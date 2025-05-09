
#
# spec'ing Xel
#
# Fri Sep 25 13:24:56 JST 2015
#

require 'spec/spec_helper'


def _eval(s); JSON.parse(JSON.dump(eval(s))); end

XEL_CASES =
  eval(File.read('spec/_xel.rb')) +
  File.read('spec/_xel_eval.txt')
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
  File.read('spec/_xel_tree.txt')
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

def trunc(s, max)
  s = s.gsub(/\s*\n\s*/, '↩  ')
  s[0..max] + (s.length > max ? '…' : '')
end

def debug_tree(dt, level=0)
  return unless dt
  #pp dt
  indent = '  ' * level
  nam = dt['name']; nam = nam ? nam.inspect : 'null'
  txt = dt['input']['string']
  off, len = dt['offset'], dt['length']
  tx = txt[off, len]
  puts "#{indent}| #{nam} #{dt['result']} #{off},#{len} #{tx.inspect}"
  dt['children'].each { |c| debug_tree(c, level + 1) }
end


describe 'xel_js' do

  before :all do

    @bro =
      make_browser(%w[
        spec/www/jaabro-1.4.1.js
        src/xel.js
      ])
  end

  describe 'XelParser' do

    describe '.parse' do

      XEL_CASES.each do |k|

        code = k[:c]
        tree = k[:t]; next unless tree

        it "parses successfully #{JSON.dump(code)}" do

          expect(@bro.eval(%{ XelParser.parse(#{JSON.dump(code)}); })
            ).to eq(tree)
        end
      end

      XEL_CASES.each do |k|

        code = k[:c]
        tree = k[:t]; next if tree
        ss1 = k[:ss1]

        it "parses successfully #{JSON.dump(code)}" do

          t = @bro.eval(%{ XelParser.parse(#{JSON.dump(code)}); })

          if ss1 && ss1[0, 1] == '∅'

            expect(t).to eq(nil)

          else

            debug_tree(
              t ? nil :
              @bro.eval(
                %{ XelParser.parse(#{JSON.dump(code)}, { debug: 2 }); }))

            expect(t.class).to eq(Array)
          end
        end
      end

      it 'parses successfully something prefixed with =' do

        expect(@bro.eval(%{ XelParser.parse('123') })
          ).to eq([ 'num', '123' ])
        expect(@bro.eval(%{ XelParser.parse(' = 123') })
          ).to eq([ 'num', '123' ])

        expect(@bro.eval(%{ Xel.parse('123') })
          ).to eq([ 'num', '123' ])
        expect(@bro.eval(%{ Xel.parse(' = 123') })
          ).to eq([ 'num', '123' ])
      end

      it 'returns null when it cannot parse' do

        expect(@bro.eval(%{ XelParser.parse('(') })).to eq(nil)
      end
    end
  end

  describe 'Xel' do

    describe '.eval' do

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

        it(t) do

          r = @bro.eval(%{
            Xel.eval(
              XelParser.parse(#{JSON.dump(code)}),
              #{JSON.dump(ctx)}); })

          if out.is_a?(Float)
            expect('%0.2f' % r).to eq('%0.2f' % out)
          elsif out.is_a?(Array)
            expect(r.size).to eq(out.size)
            out.zip(r).each do |rese, re|
              #expect(re.class).to eq(rese.class)
              if rese.is_a?(Float)
                expect('%0.2f' % re).to eq('%0.2f' % rese)
              else
                expect(re).to eq(rese)
              end
            end
          else
            expect(r).to eq(out)
          end
        end
      end

      it "does not mind a prefix =" do

        expect(@bro.eval(%{ Xel.eval("123"); })).to eq(123)
        expect(@bro.eval(%{ Xel.eval("= 123"); })).to eq(123)
        expect(@bro.eval(%{ Xel.eval("  = 123"); })).to eq(123)
        expect(@bro.eval(%{ Xel.eval("	= 123"); })).to eq(123)
        expect(@bro.eval(%q{ Xel.eval("\n = MAX(123, 234)"); })).to eq(234)
        expect(@bro.eval(%{ Xel.eval("0"); })).to eq(0)
        expect(@bro.eval(%{ Xel.eval("= 0"); })).to eq(0)
        expect(@bro.eval(%{ Xel.eval(" = 0"); })).to eq(0)
      end

      context 'custom functions' do

        they 'work' do

          r = @bro.eval(%{
            Xel.eval(
              'Plus(1, 1)',
              ctx = {
                a: 0,
                Plus: function(tree, context) {
                  return [ tree[0], Object.keys(context) ];
                }
              }); })

          expect(r).to eq([ 'Plus', %w[ a Plus ] ])
        end
      end

      context 'VLOOKUP()' do

        before :each do
          @ctx = {
            table0: [
              [ 'finds - nada hello', 1.1 ],
              [ 'finds - income', 1.2 ],
              [ 'mac g - income', 1.3 ] ] }
        end

        it 'looks up and finds' do

          r = @bro.eval(%{
            Xel.eval(
              "VLOOKUP('finds - income', table0, 2)",
              #{JSON.dump(@ctx)}); })

          expect(r).to eq(1.2)
        end

        it 'looks up and finds, or not' do

          r = @bro.eval(%{
            Xel.eval(
              `{ VLOOKUP('finds - income', table0, 2),
                 VLOOKUP('mac g - income', table0, 2),
                 VLOOKUP('fubar', table0, 2),
                 VLOOKUP('finds - nada hello', table0, 2) }`,
              #{JSON.dump(@ctx)}); })

          expect(r).to eq([ 1.2, 1.3, 1.1 ])
        end

        it 'looks up and finds not' do

          r = @bro.eval(%{
            Xel.eval(
              "VLOOKUP('fubar', table0, 2)",
              #{JSON.dump(@ctx)}); })

          expect(r).to eq(nil)
        end

        it 'fails' do

          expect {
            @bro.eval(%{
              Xel.eval(
                "VLOOKUP('fubar', table0, 'abc')",
                #{JSON.dump(@ctx)}); })
          }.to raise_error(
            Ferrum::JavaScriptError,
            /VLOOKUP.. arg 3 'str,abc' is not a number/
          )
        end
      end

      context 'lambdas' do

        they 'have a _source' do

          r = @bro.eval(%{ Xel.eval("LAMBDA(a, b, a + b)", {})._source })

          expect(r).to eq('LAMBDA(a, b, a + b)')
        end
      end

      context 'callbacks' do

        they 'are called twice per each `eval` step' do

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

          expect(
            r
          ).to eq([
            [["plus", ["num", "12"], ["var", "a"]], {"a"=>34}],
            [["num", "12"], {"a"=>34}],
            [["num", "12"], {"a"=>34}, 12],
            [["var", "a"], {"a"=>34}],
            [["var", "a"], {"a"=>34}, 34],
            [["plus", ["num", "12"], ["var", "a"]], {"a"=>34}, 46]
          ])
        end
      end

      context 'ctx._callbacks' do

        they 'are called twice per each `eval` step' do

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

          expect(
            r
          ).to eq([
            [["plus", ["num", "12"], ["var", "a"]]],
            [["num", "12"]],
            [["num", "12"], 12],
            [["var", "a"]],
            [["var", "a"], 35],
            [["plus", ["num", "12"], ["var", "a"]], 47]
          ])
        end
      end
    end

    describe '.s_eval' do

      it 'evals if the input is a string' do

        expect(@bro.eval(%{ Xel.s_eval('12 * 12'); })).to eq(144)
      end

      it 'returns the input immediately if it is not a a string' do

        expect(@bro.eval(%{ Xel.s_eval(true); })).to eq(true)
      end
    end

    describe '.sash' do

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

        it "returns #{v} for '#{k}'" do

#puts @bro.eval(%{ Xel.sash(#{k.inspect}); }.strip)
          expect(@bro.eval(%{
            Xel.sash(#{k.inspect});
          }.strip)).to eq(v)
        end
      end
    end
  end
end

