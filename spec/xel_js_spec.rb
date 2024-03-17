
#
# spec'ing Xel
#
# Fri Sep 25 13:24:56 JST 2015
#

require 'spec/spec_helper'


describe 'xel_js' do

  before :all do
    @bro =
      make_browser(%w[
        spec/www/jaabro-1.4.0.js
        src/xel.js
      ])
  end

  describe 'XelParser' do

    describe '.parse' do

      #it 'returns null when it cannot parse'

      Kernel.eval(File.read('spec/_xel_parse.rb'))
        .each_slice(2) do |code, tree|

          it "parses successfully #{JSON.dump(code)}" do

            expect(@bro.eval(%{ XelParser.parse(#{JSON.dump(code)}); })
              ).to eq(tree)
          end
        end
    end
  end

  describe 'Xel' do

    describe '.eval' do

      Kernel.eval(File.read('spec/_xel_eval.rb')).each do |code, ctx, result|

        t =
          "evals #{code.inspect} to #{result.inspect}" +
          (ctx.any? ? ' when ' + ctx.inspect : '')

        it(t) do

          r = @bro.eval(%{
            Xel.eval(
              XelParser.parse(#{JSON.dump(code)}),
              #{JSON.dump(ctx)}); })

          if result.is_a?(Float)
            expect('%0.2f' % r).to eq('%0.2f' % result)
          elsif result.is_a?(Array)
            expect(r.size).to eq(result.size)
            result.zip(r).each do |rese, re|
              #expect(re.class).to eq(rese.class)
              if rese.is_a?(Float)
                expect('%0.2f' % re).to eq('%0.2f' % rese)
              else
                expect(re).to eq(rese)
              end
            end
          else
            expect(r).to eq(result)
          end
        end
      end

      context 'custom functions' do

        they 'work' do

          r = @bro.eval(%{
            Xel.seval(
              'Plus(1, 1)',
              ctx = { a: 0, _custom_functions: {
                Plus: function(tree, context) {
                  return [ tree[0], Object.keys(context) ];
                }
              } }); })

          expect(r).to eq([ 'Plus', %w[ a _custom_functions _eval ] ])
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
            Xel.seval(
              "VLOOKUP('funds - income', table0, 2)",
              #{JSON.dump(@ctx)}); })

          expect(r).to eq(1.2)
        end

        it 'looks up and finds, or not' do

          r = @bro.eval(%{
            Xel.seval(
              `{ VLOOKUP('finds - income', table0, 2),
                 VLOOKUP('mac g - income', table0, 2),
                 VLOOKUP('fubar', table0, 2),
                 VLOOKUP('finds - nada hello', table0, 2) }`,
              #{JSON.dump(@ctx)}); })

          expect(r).to eq([ 1.2, 1.3, 1.1 ])
        end

        it 'looks up and finds not' do

          r = @bro.eval(%{
            Xel.seval(
              "VLOOKUP('fubar', table0, 2)",
              #{JSON.dump(@ctx)}); })

          expect(r).to eq(nil)
        end

        it 'fails' do

          expect {
            @bro.eval(%{
              Xel.seval(
                "VLOOKUP('fubar', table0, 'abc')",
                #{JSON.dump(@ctx)}); })
          }.to raise_error(
            Ferrum::JavaScriptError,
            /VLOOKUP.. arg 3 'str,abc' is not a number/
          )
        end
      end
    end

    describe '.peval' do

      Kernel.eval(File.read('spec/_xel_peval.rb')).each do |code, ctx, result|

        t =
          "evals #{code.inspect} to #{result.inspect}" +
          (ctx.any? ? ' when ' + ctx.inspect : '')

        it(t) do

          r = @bro.eval(%{
            Xel.peval(
              XelParser.parse(#{JSON.dump(code)}),
              #{JSON.dump(ctx)}); })

          expect(r).to eq(result)
        end
      end
    end
  end
end

