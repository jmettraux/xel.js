
#
# spec'ing Xel
#
# Fri Sep 25 13:24:56 JST 2015
#


def _eval(s); JSON.parse(JSON.dump(eval(s))); end

XEL_CASES =
  eval(File.read('test/_xel.rb')) +
  File.read('test/_xel_eval.txt')
    .gsub(/\\\n/, '')
    .split("\n")
    .inject([]) { |a, l|
      ss = l.strip.split(/[→⟶]/)
      if ss.length == 2
        a << { c: ss[0], o: _eval(ss[1].strip) }
      elsif ss.length >= 3
        a << { c: ss[0], ctx: _eval(ss[1]), o: _eval(ss[2]) }
      end
      a } +
  File.read('test/_xel_tree.txt')
    .split(/]$/)
    .map { |ll|
      (ll + ']').strip.split("\n").reject { |s| s.match(/^\s*#/) }.join('') }
    .inject([]) { |a, l|
      ss = l.strip.split(/[→⟶]/)
      if ss.length > 1
        ss1 = ss[1].strip
        t = ss1[0, 1] == '∅' ? nil : eval(ss1)
        a << { c: ss[0], t: t, ss1: ss1 }
      end
      a }
#pp XEL_CASES; p XEL_CASES.length


group 'xel_js' do

  setup do

    @bro =
      make_browser(%w[
        test/www/jaabro-1.4.1.js
        src/xel.js
      ])
  end

  group 'XelParser' do

    group '.parse' do

      XEL_CASES.each do |k|

        code = k[:c]
        tree = k[:t]; next unless tree

        test "parses successfully #{JSON.dump(code)}" do

          assert @bro.eval(%{ XelParser.parse(#{JSON.dump(code)}); }), tree
        end
      end

      XEL_CASES.each do |k|

        code = k[:c]
        tree = k[:t]; next if tree
        ss1 = k[:ss1]

        test "parses successfully #{JSON.dump(code)}" do

          t = @bro.eval(%{ XelParser.parse(#{JSON.dump(code)}); })

          if ss1 && ss1[0, 1] == '∅'

            assert t, nil

          else

            debug_tree(
              t ? nil :
              @bro.eval(
                %{ XelParser.parse(#{JSON.dump(code)}, { debug: 2 }); }))

            assert t.class, Array
          end
        end
      end

      test 'parses successfully something prefixed with =' do

        assert @bro.eval(%{ XelParser.parse('123') }), [ 'num', '123' ]
        assert @bro.eval(%{ XelParser.parse(' = 123') }), [ 'num', '123' ]

        assert @bro.eval(%{ Xel.parse('123') }), [ 'num', '123' ]
        assert @bro.eval(%{ Xel.parse(' = 123') }), [ 'num', '123' ]
      end

      test 'returns null when it cannot parse' do

        assert @bro.eval(%{ XelParser.parse('(') }), nil
      end
    end
  end

  group 'Xel' do

    group '.eval' do

      XEL_CASES.each do |k|

        next unless k.has_key?(:o)
        code = k[:c]
        ctx = k[:ctx] || {}
        out = k[:o]

        l =
          ctx.any? ? 29 : 56
        t =
          "evals #{trunc(code, l)} to #{trunc(out.inspect, l)}" +
          (ctx.any? ? ' when ' + trunc(ctx.inspect, l) : '')

        test(t) do

          r = @bro.eval(%{
            Xel.eval(
              XelParser.parse(#{JSON.dump(code)}),
              #{JSON.dump(ctx)}); })

          if out.is_a?(Float)
            assert '%0.2f' % r, '%0.2f' % out
          elsif out.is_a?(Array)
            assert r.size, out.size
            out.zip(r).each do |rese, re|
              if rese.is_a?(Float)
                assert '%0.2f' % re, '%0.2f' % rese
              else
                assert re, rese
              end
            end
          else
            assert r, out
          end
        end
      end

      test "does not mind a prefix =" do

        assert @bro.eval(%{ Xel.eval("123"); }), 123
        assert @bro.eval(%{ Xel.eval("= 123"); }), 123
        assert @bro.eval(%{ Xel.eval("  = 123"); }), 123
        assert @bro.eval(%{ Xel.eval("	= 123"); }), 123
        assert @bro.eval(%q{ Xel.eval("\n = MAX(123, 234)"); }), 234
        assert @bro.eval(%{ Xel.eval("0"); }), 0
        assert @bro.eval(%{ Xel.eval("= 0"); }), 0
        assert @bro.eval(%{ Xel.eval(" = 0"); }), 0
      end

      group 'custom functions' do

        test 'work' do

          r = @bro.eval(%{
            Xel.eval(
              'Plus(1, 1)',
              ctx = {
                a: 0,
                Plus: function(tree, context) {
                  return [ tree[0], Object.keys(context) ];
                }
              }); })

          assert r, [ 'Plus', %w[ a Plus ] ]
        end
      end

      group 'VLOOKUP()' do

        setup do

          @ctx = {
            table0: [
              [ 'finds - nada hello', 1.1 ],
              [ 'finds - income', 1.2 ],
              [ 'mac g - income', 1.3 ] ] }
        end

        test 'looks up and finds' do

          r = @bro.eval(%{
            Xel.eval(
              "VLOOKUP('finds - income', table0, 2)",
              #{JSON.dump(@ctx)}); })

          assert r, 1.2
        end

        test 'looks up and finds, or not' do

          r = @bro.eval(%{
            Xel.eval(
              `{ VLOOKUP('finds - income', table0, 2),
                 VLOOKUP('mac g - income', table0, 2),
                 VLOOKUP('fubar', table0, 2),
                 VLOOKUP('finds - nada hello', table0, 2) }`,
              #{JSON.dump(@ctx)}); })

          assert r, [ 1.2, 1.3, 1.1 ]
        end

        test 'looks up and finds not' do

          r = @bro.eval(%{
            Xel.eval(
              "VLOOKUP('fubar', table0, 2)",
              #{JSON.dump(@ctx)}); })

          assert r, nil
        end

        test 'fails' do

          assert_error(
            lambda {
              @bro.eval(%{
                Xel.eval(
                  "VLOOKUP('fubar', table0, 'abc')",
                  #{JSON.dump(@ctx)}); }) },
            Ferrum::JavaScriptError,
            /VLOOKUP.. arg 3 'str,abc' is not a number/)
        end
      end

      group 'lambdas' do

        test 'have a _source' do

          r = @bro.eval(%{ Xel.eval("LAMBDA(a, b, a + b)", {})._source })

          assert r, 'LAMBDA(a, b, a + b)'
        end
      end

      group 'callbacks' do

        test 'are called twice per each `eval` step' do

          r = @bro.eval(%{
            (function() {
              var a = [];
              Xel.callbacks.push(function(tree, context, ret) {
                a.push([ tree, context, ret ]);
              });
              Xel.eval("12 + a", { a: 34 });
              Xel.callbacks.pop();
              return a;
            }()); })

          assert(
            r,
            [ [["plus", ["num", "12"], ["var", "a"]], {"a"=>34}],
              [["num", "12"], {"a"=>34}],
              [["num", "12"], {"a"=>34}, 12],
              [["var", "a"], {"a"=>34}],
              [["var", "a"], {"a"=>34}, 34],
              [["plus", ["num", "12"], ["var", "a"]], {"a"=>34}, 46] ])
        end
      end

      group 'ctx._callbacks' do

        test 'are called twice per each `eval` step' do

          r = @bro.eval(%{
            (function() {
              var a =
                [];
              var cb =
                function(tree, context, ret) {
                  a.push([ tree, ret ]);
                };
              var ctx =
                { a: 35, _callbacks: [ cb ] };
              Xel.eval("12 + a", ctx);
              return a;
            }()); })

          assert(
            r,
            [ [["plus", ["num", "12"], ["var", "a"]]],
              [["num", "12"]],
              [["num", "12"], 12],
              [["var", "a"]],
              [["var", "a"], 35],
              [["plus", ["num", "12"], ["var", "a"]], 47] ])
        end
      end
    end

    group '.s_eval' do

      test 'evals if the input is a string' do

        assert @bro.eval(%{ Xel.s_eval('12 * 12'); }), 144
      end

      test 'returns the input immediately if it is not a a string' do

        assert @bro.eval(%{ Xel.s_eval(true); }), true
      end
    end

    group '.sash' do

      { '' =>
          '|||0|0',
        'foo' =>
          'foo|o|foo|3|849955110',
        'bar' =>
          'bar|a|bar|3|815990707',
        'The quick brown fox jumps over the lazy dog.' =>
          'The qui|m|zy dog.|44|8835820411',
        'Lorem ipsum dolor sit amet, consectetur adip' =>
          'Lorem i|a|ur adip|44|-6470139925',
      }.each do |k, v|

        test "returns #{v} for '#{k}'" do

#puts @bro.eval(%{ Xel.sash(#{k.inspect}); }.strip)
          assert @bro.eval(%{ Xel.sash(#{k.inspect}); }.strip), v
        end
      end
    end
  end
end

