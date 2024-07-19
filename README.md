
# xel.js

Interpreting expressions built out of a subset of spreadsheet functions.

Has a little Ruby twin, [xel.rb](https://github.com/jmettraux/xel.rb).

```js
// Xel.seval(code, context)
//   where context is a mapping var_name -> var_value

Xel.seval("	= CASE(a<5000000, 0.6, a<10000000, 0.55, 0.45)", { a: 10000 })
// --> 0.6

Xel.seval("CASE(a<5000000, 0.6, a<10000000, 0.55, 0.45)", { a: 5_100_000 })
// --> 0.55
```

Here are the eval tests, in the format `code [ ⟶   context] ⟶   result`

```
987 ⟶   987
3,000,000 ⟶   3_000_000
123.45 ⟶   123.45
9,090.10 ⟶   9_090.1
.123 ⟶   0.123
-987 ⟶   -987
-3,000,000 ⟶   -3_000_000
-123.45 ⟶   -123.45
-9,090.10 ⟶   -9_090.10
-.123 ⟶   -0.123

"12" =~ "[a-z]" ⟶   false
"a" != "a" ⟶    false
"a" != "b" ⟶    true
"a" = "a" ⟶    true
"a" = "b" ⟶    false
"a" IN { 0, "a", 2 } ⟶   true
"a" IN { 0, "b", 2 } ⟶   false
"a" IN {} ⟶   false
"ab" =~ "[a-z]" ⟶   true

"b" IN a ⟶   {"a":["a","b","c"]} ⟶   true
"d" IN a ⟶   {"a":["a","b","c"]} ⟶   false

{ "a" } != { "a" } ⟶   false
{ "a" } != { "b" } ⟶   true
{ "a" } = { "a" } ⟶   true
{ "a" } = { "b" } ⟶   false
{ "a", "b" } != { "a" } ⟶   true
{ "a", "b" } != { "a", "b" } ⟶   false
{ "a", "b" } = { "a" } ⟶   false
{ "a", "b" } = { "a", "b" } ⟶   true
{ 1, "a", "b", "c" } ⟶   [ 1, "a", "b", "c" ]
{ 1, 2 } + { "a", "b" } ⟶   [ 1, 2, "a", "b" ]
{ { "a", "b" }, { "c", "de" } } ⟶   [ [ "a", "b" ], [ "c", "de" ] ]
{ { "a", 1 }, { "c", 2 } } ⟶   [ [ "a", 1 ], [ "c", 2 ] ]
{ "a", "b", "c" } ⟶   [ "a", "b", "c" ]
{ "a","b" } ⟶   [ "a", "b" ]

LET(price, 100, count, 3, count * price) ⟶   300
LET(price, 95, count, 3, 12, count * price) ⟶   285
LET(price, 13, LOWER("COUNT"), 3, count * price) ⟶   39
LET(l, LAMBDA(a, b, a + b), l(2, 3)) ⟶   5
LET(_l, LAMBDA(a, b, a * b), _l(2, 3)) ⟶   6

ROUND(3.14159) ⟶   3
ROUND(3.14159, 0) ⟶   3
ROUND(3.14159, 2) ⟶   3.14
ROUND(157, -1) ⟶   160
ROUND(157, -2) ⟶   200
ROUND(2.678, 1) ⟶   2.7

MROUND(51, 3) ⟶   51
MROUND(50, 7) ⟶   49
MROUND(50, 3) ⟶   51
MROUND(10, 3) ⟶   9
MROUND(10, -3) ⟶   nil
MROUND(-10, 3) ⟶   nil
MROUND(-10, -3) ⟶   -9
MROUND(0, 3) ⟶   0
MROUND(10, 0) ⟶   nil
MROUND(10.5, 0.3) ⟶   10.5
MROUND(5, 3) ⟶   6
MROUND(4, 3) ⟶   3
MROUND(10.5678, 0.05) ⟶   10.55

  # need MROUND2 for the job, but why again?
  #
MROUND2(51, 3) ⟶   51
MROUND2(50, 7) ⟶   49
MROUND2(50, 3) ⟶   51
MROUND2(10, 3) ⟶   9
MROUND2(10, -3) ⟶   nil
MROUND2(-10, 3) ⟶   nil
MROUND2(-10, -3) ⟶   -9
MROUND2(0, 3) ⟶   0
MROUND2(10, 0) ⟶   nil
MROUND2(10.5, 0.3) ⟶   10.5
MROUND2(5, 3) ⟶   6
MROUND2(4, 3) ⟶   3
MROUND2(10.5678, 0.05) ⟶   10.55

CEILING(7, 1) ⟶   7
CEILING(7) ⟶   7
CEILING(7.05, 1) ⟶   8
CEILING(7.05) ⟶   8
CEILING(7, 5) ⟶   10
CEILING(49.25, 5) ⟶   50
CEILING(501, 100) ⟶   600
CEILING(550, 100) ⟶   600
CEILING(10.1, 0.25) ⟶   10.25

FLOOR(7, 5) ⟶   5
FLOOR(49.25) ⟶   49
FLOOR(49.25, 1) ⟶   49
FLOOR(550, 100) ⟶   500
FLOOR(10.1, 0.25) ⟶   10

TRUNC(8.9) ⟶   8
TRUNC(8.9, 0) ⟶   8
TRUNC(3.14159, 2) ⟶   3.14
TRUNC(2.678, 1) ⟶   2.6

"ab\"cd'ef" ⟶   "ab\"cd'ef"
'ab"cd\'ef' ⟶   "ab\"cd'ef"

0.45 * we_c - 0.15 * it_c + 0.15 * sm_c + 0.25 * gp_c ⟶   \
  {:we_c=>1.1, :it_c=>2.2, :sm_c=>3.3, :gp_c=>4.4} ⟶   1.76

1 + "a" ⟶   "1a"
1 + 2 ⟶   3
1 + a.b.c ⟶   {:a=>{:b=>{:c=>66}}} ⟶   67
1 + v0 ⟶   {:v0=>70} ⟶   71
1 - -2 ⟶   3
1 - 2 ⟶   -1
1 / 5 ⟶   0.2
"a" & "bc" ⟶   "abc"
1 & 1 ⟶   "11"
"ab" & c & d & "ef" ⟶   {:c=>"c"} ⟶   "abcef"
1 < 2 ⟶   true
1 <= 2 ⟶   true
1 IN a ⟶   {:a=>[0, 1, 2]} ⟶   true
1 IN { 0, 1 } ⟶   true
1.0 / 5 ⟶   0.2
2 != 3 ⟶   true
2 <= 2 ⟶   true
2 >= 2 ⟶   true
3 = 3 ⟶   true
3 >= 2 ⟶   true

AND(TRUE()) ⟶   true
AND(TRUE(), TRUE()) ⟶   true

CASE(AND(a > 99, 2 > 1), 2, a > 9, 1, -1) ⟶   {:a=>100} ⟶   2
CASE(a > 99, 2, a > 9, 1, -1) ⟶   {:a=>100} ⟶   2
CASE(eb, "&", 10, "g", 11, "a", 12, 13) ⟶   {:eb=>"nada"} ⟶   13

COUNTA(a) ⟶   {:a=>[]} ⟶   0
COUNTA(a) ⟶   {:a=>[1, 2, 3]} ⟶   3

HAS(a, "b") ⟶   {:a=>["a", "b", "c"]} ⟶   true
HAS(a, 1) ⟶   {:a=>[0, 1, 2]} ⟶   true

IF(FALSE(), 1, 2) ⟶   2
IF(TRUE(), 1, 2) ⟶   1
IF(f, 1, 2) ⟶   {:f=>false} ⟶   2
IF(t, 1, 2) ⟶   {:t=>true} ⟶   1

INDEX(a, -1) ⟶   {:a=>[0, 1, 2, "trois"]} ⟶   "trois"
INDEX(a, -2) ⟶   {:a=>[0, 1, 2, "trois"]} ⟶   2
INDEX(a, 1) ⟶   {:a=>[0, 1, 2]} ⟶   0
INDEX(a, 2) ⟶   {:a=>[0, 1, 2]} ⟶   1
INDEX(a, COUNTA(a)) ⟶   {:a=>[0, "two"]} ⟶   "two"
INDEX({ 'ab', 'cd', 'ef' }, -2) ⟶   "cd"

ISBLANK(a) ⟶   {:a=>""} ⟶   true
ISBLANK(a) ⟶   {} ⟶   true

ISNUMBER(123) ⟶   true
ISNUMBER(123.12) ⟶   true

LN(3044.31) ⟶   8.02
LN(a) ⟶   {:a=>[3044.31, 3047.12]} ⟶   [8.02, 8.02]
LN({ 3044.31, 3047.12 }) ⟶   [8.02, 8.02]

MATCH("b", a, 0) ⟶   {:a=>["a", "b", "c"]} ⟶   1
MATCH("d", a, 0) ⟶   {:a=>["a", "b"]} ⟶   -1
MATCH(1, a, 0) ⟶   {:a=>[0, 1, 2]} ⟶   1

MAX(-1, -2, "a", -3) ⟶   -1
MAX(-1, -2, -3) ⟶   -1
MAX(1, 2, 3) ⟶   3
MIN(-1, -2, "a", -3) ⟶   -1
MIN(-1, -2, -3) ⟶   -3
MIN(1, 2, 3) ⟶   1
NOT(FALSE()) ⟶   true

OR(1 = 2, 2 = 2) ⟶   true
OR(TRUE(), FALSE()) ⟶   true

PRODUCT(2, 3, 4) ⟶   24
PRODUCT({ 2, 3, 4 }) ⟶   24
PRODUCT({ 2, 3, 4 }, 2) ⟶   48
PRODUCT({ 2, 3, 4 }, a, 2) ⟶   {:a=>[0.5, 0.5]} ⟶   12

PROPER("alpha bravo charly") ⟶   "Alpha Bravo Charly"

SORT({ 1, "aa", 7, 2 }, 1, -1) ⟶   ["aa", 7, 2, 1]
SORT({ 1, 3, 2 }) ⟶   [1, 2, 3]
SORT({ 1, 3, 2 }, 1, -1) ⟶   [3, 2, 1]

SQRT(260) ⟶   16.1245
SQRT(a) ⟶   {:a=>[260, 81]} ⟶   [16.1245, 9]
SQRT({ 260, 81 }) ⟶   [16.1245, 9]

STDEV(a) ⟶   {:a=>[10, 11]} ⟶   0.71

SUM(2, 3, 4) ⟶   9
SUM({ 2, 3, 4 }) ⟶   9
SUM({ 2, 3, 4 }, 2) ⟶   11
SUM({ 2, 3, 4 }, a, 2) ⟶   {:a=>[0.5, 0.5]} ⟶   12

TRUE() ⟶   true

UNIQUE(a) ⟶   {:a=>[1, 2, 1, 1, 2, 3]} ⟶   [1, 2, 3]
UNIQUE({ 1, 1 }) ⟶   [1]

UPPER("alpha bravo charly") ⟶   "ALPHA BRAVO CHARLY"
LOWER("ALPHA BRAVO Charly") ⟶   "alpha bravo charly"

a != "" ⟶   {:a=>"abc"} ⟶   true

LAMBDA(a, b, a + b) ⟶   {}

KALL(LAMBDA(a, b, a + b), 7, -3) ⟶   4
KALL(LAMBDA(a, b, a + b), 7, -2, 1) ⟶   5

MAP({ 2, 3, 4 }, LAMBDA(a, 2 * a)) ⟶   [4, 6, 8]

REDUCE(0, { 2, 3, 4 }, LAMBDA(a, e, a + e)) ⟶   9
REDUCE({ 2, 3, 5 }, LAMBDA(a, e, a + e)) ⟶   10

ORV('', '', 1) ⟶   1
ORV('', b, a, 3) ⟶   {:a=>2} ⟶   2

TEXTJOIN("/", TRUE(), "a", "b") ⟶   "a/b"
TEXTJOIN(", ", TRUE(), a, "zz") ⟶   {:a=>["ab", "cd", "ef1"]} ⟶   "ab, cd, ef1, zz"
TEXTJOIN(", ", TRUE(), a, "zz") ⟶   {:a=>["ab", "", "ef1"]} ⟶   "ab, ef1, zz"
TEXTJOIN(", ", FALSE(), a, "zz") ⟶   {:a=>["ab", "", "ef1"]} ⟶   "ab, , ef1, zz"

D() ⟶   \
  {}
D('alpha') ⟶   \
  { alpha: nil }
D('alpha', 'bravo') ⟶   \
  { alpha: 'bravo' }
D('a', 1, 'b', 'deux', 'charly', { 1, 'deux' }) ⟶   \
  { a: 1, b: 'deux', charly: [ 1, 'deux' ] }
```

See core spec at [spec/_xel.rb](spec/_xel.rb).


## callbacks

Callback methods can be added to `Xel.callbacks` directly:

```js
var a = [];
Xel.callbacks.push(function(tree, context, ret) {
  a.push([ tree, context, ret ]);
});
Xel.seval("12 + a", { a: 34 });
Xel.callbacks.pop(); // remove last callback ;-)

// a -->

[
  [ [ 'plus', [ 'num', '12' ], [ 'var', 'a' ] ],  { a: 34 } ],
  [ [ 'num', '12' ],                              { a: 34 } ],
  [ [ 'num', '12' ],                              { a: 34 },    12 ],
  [ [ 'var', 'a' ],                               { a: 34 } ],
  [ [ 'var', 'a' ],                               { a: 34 },    34 ],
  [ [ 'plus', [ 'num', '12' ], [ 'var', 'a' ] ],  { a: 34 },    46 ]
]
```

Callbacks may also be added more transiently by providing a `_callbacks` array in the eval context:

```js
var a = [];
var cb = function(tree, context, ret) { a.push([ tree, ret ]); };
var ctx = { a: 35, _callbacks: [ cb ] };
Xel.seval("12 + a", ctx);

// a -->

[
  [ [ 'plus', [ 'num', '12' ], [ 'var', 'a' ] ] ],
  [ [ 'num', '12' ] ],
  [ [ 'num', '12' ],                                12 ],
  [ [ 'var', 'a' ] ],
  [ [ 'var', 'a' ], 35 ],
  [ [ 'plus', [ 'num', '12' ], [ 'var', 'a' ] ],    47 ]
]
```


## cdn

```html
<script src="https://cdn.jsdelivr.net/gh/jmettraux/xel.js@1.4.0/spec/www/jaabro-1.4.0.js"></script>
<script src="https://cdn.jsdelivr.net/gh/jmettraux/xel.js@1.4.0/src/xel.js"></script>
```


## License

MIT, see [LICENSE.txt](LICENSE.txt)

