
#
# spec'ing Xel, Javascript
#
# Tue Aug  4 13:45:38 JST 2020
#

[
  [ '1 + 2', {}, '(1 + 2)' ],
  [ '1 - 2', {}, '(1 + (- 2))' ],
  [ '1 - -2', {}, '(1 + 2)' ],
  [ '1 / 5', {}, '(1 * (1 / 5))' ],
  [ '1.0 / 5', {}, '(1.0 * (1 / 5))' ],
  [ '1 + "a"', {}, '(1 + "a")' ],

  [ '1 + v0', { v0: 70 }, '(1 + v0:70)' ],
  [ '1 + a.b.c', { a: { b: { c: 66 } } }, '(1 + a.b.c:66)' ],

  [ '1 < 2', {}, '(1 < 2)' ],
  [ '1 > 2', {}, '(1 > 2)' ],
  [ '1 <= 2', {}, '(1 <= 2)' ],
  [ '2 >= 2', {}, '(2 >= 2)' ],
  [ '2 = 3', {}, '(2 = 3)' ],
  [ '3 != 3', {}, '(3 != 3)' ],
  [ '"a" = "b"', {}, '("a" = "b")' ],
  [ '"a" != "b"', {}, '("a" != "b")' ],

  [ '"ab" =~ "[a-z]"', {}, '("ab" =~ "[a-z]")'  ],
  [ '"12" =~ "[a-z]"', {}, '("12" =~ "[a-z]")'  ],

  [ 'TRUE()', {}, 'TRUE()' ],
  [ 'FALSE()', {}, 'FALSE()' ],
  [ 'IF(FALSE(), 1, 2)', {}, 'IF(FALSE(), 1, 2)' ],
  [ 'IF(TRUE(), 1, 2)', {}, 'IF(TRUE(), 1, 2)' ],
  [ 'IF(t, 1, 2)', { t: true }, 'IF(t:true, 1, 2)' ],
  [ 'IF(f, 1, 2)', { f: false }, 'IF(f:false, 1, 2)' ],

  [ 'AND(TRUE())', {}, 'AND(TRUE())' ],
  [ 'AND(FALSE())', {}, 'AND(FALSE())' ],
  [ 'AND(TRUE(), TRUE())', {}, 'AND(TRUE(), TRUE())' ],
  [ 'AND(TRUE(), FALSE())', {}, 'AND(TRUE(), FALSE())' ],
  [ 'OR(TRUE(), FALSE())', {}, 'OR(TRUE(), FALSE())' ],
  [ 'NOT(TRUE())', {}, 'NOT(TRUE())' ],
  [ 'NOT(FALSE())', {}, 'NOT(FALSE())' ],

  [ 'OR(1 = 2, 2 = 3)', {}, 'OR((1 = 2), (2 = 3))' ],
  [ 'OR(1 = 2, 2 = 2)', {}, 'OR((1 = 2), (2 = 2))' ],

  [ 'ISBLANK(a)', {}, 'ISBLANK(a:-)' ],
  [ 'ISBLANK(a)', { 'a' => '' }, 'ISBLANK(a:"")' ],
  [ 'ISBLANK(a)', { 'a' => 'abc' }, 'ISBLANK(a:"abc")' ],

  [ 'ISNUMBER(a)', {}, 'ISNUMBER(a:-)' ],
  [ 'ISNUMBER(a)', { 'a' => nil }, 'ISNUMBER(a:-)' ],
  [ 'ISNUMBER("nada")', {}, 'ISNUMBER("nada")' ],
  [ 'ISNUMBER(TRUE())', {}, 'ISNUMBER(TRUE())' ],
  [ 'ISNUMBER(FALSE())', {}, 'ISNUMBER(FALSE())' ],
  [ 'ISNUMBER(123)', {}, 'ISNUMBER(123)' ],
  [ 'ISNUMBER(123.12)', {}, 'ISNUMBER(123.12)' ],

  [ 'a = ""', {}, '(a:- = "")' ],
  [ 'a = ""', { 'a' => '' }, '(a:"" = "")' ],
  [ 'a = ""', { 'a' => true }, '(a:true = "")' ],
  [ 'a = ""', { 'a' => 'abc' }, '(a:"abc" = "")' ],
  [ 'a != ""', {}, '(a:- != "")' ],
  [ 'a != ""', { 'a' => true }, '(a:true != "")' ],
  [ 'a != ""', { 'a' => '' }, '(a:"" != "")' ],
  [ 'a != ""', { 'a' => 'abc' }, '(a:"abc" != "")' ],

  [ 'ntac = "yes"', { 'ntac' => 'yes' }, '(ntac:"yes" = "yes")' ],
  [ 'ntac = "yes"', { 'ntac' => 'no' }, '(ntac:"no" = "yes")' ],

  [ 'CASE(eb, "&", 10, "g", 11, "a", 12, 13)', { 'eb' => '&' },
    'CASE(eb:"&", "&", 10, "g", 11, "a", 12, 13)' ],
  [ 'CASE(a > 99, 2, a > 9, 1)', { 'a' => 7 },
    'CASE((a:7 > 99), 2, (a:7 > 9), 1)' ],
  [ 'CASE(a > 99, 2, a > 9, 1, -1)', { 'a' => 100 },
    'CASE((a:100 > 99), 2, (a:100 > 9), 1, -1)' ],
  [ 'CASE(AND(a > 99, 2 > 1), 2, a > 9, 1, -1)', { 'a' => 100 },
    'CASE(AND((a:100 > 99), (2 > 1)), 2, (a:100 > 9), 1, -1)' ],

  [ 'MATCH(1, a, 0)', { 'a' => [ 0, 1, 2 ] }, 'MATCH(1, a:{0,1,2}, 0)' ],
  [ 'MATCH("d", a, 0)', { 'a' => %w[ a b ] }, 'MATCH("d", a:{"a","b"}, 0)' ],

  [ 'HAS(a, 1)', { 'a' => [ 0, 1, 2 ] }, 'HAS(a:{0,1,2}, 1)' ],
  [ 'HAS(a, "b")', { 'a' => %w[ a b c ] }, 'HAS(a:{"a","b","c"}, "b")' ],

  [ '1 IN a', { 'a' => [ 0, 1, 2 ] }, '(1 IN a:{0,1,2})' ],
  [ '"b" IN a', { 'a' => %w[ a b c ] }, '("b" IN a:{"a","b","c"})' ],
  [ '1 IN { 0, 1 }', {}, '(1 IN {0,1})' ],
  [ '"a" IN { 0, "a", 2 }', {}, '("a" IN {0,"a",2})' ],
  [ '"a" IN {}', {}, '("a" IN {})' ],

  [ "'ab\"cd\\'ef'", {}, '"ab\"cd\'ef"' ],
  [ "\"ab\\\"cd'ef\"", {}, '"ab\"cd\'ef"' ],

  [ '{ 1, "a", "b", "c" } ', {}, '{1,"a","b","c"}' ],
  [ '{ 1, 2 } + { "a", "b" }', {}, '({1,2} + {"a","b"})' ],

  [ 'INDEX(a, 1)', { 'a' => [ 0, 1, 2 ] },
    'INDEX(a:{0,1,2}, 1)' ],
  [ 'COUNTA(a)', { 'a' => [] },
    'COUNTA(a:{})' ],
  [ 'INDEX(a, COUNTA(a))', { 'a' => [ 0, 'two' ] },
    'INDEX(a:{0,"two"}, COUNTA(a:{0,"two"}))' ],
  [ 'INDEX(a, -1)', { 'a' => [ 0, 1, 2, 'trois' ] },
    'INDEX(a:{0,1,2,"trois"}, -1)' ],

  [ 'PROPER("alpha bravo charly")', {}, 'PROPER("alpha bravo charly")' ],
  [ 'UPPER("alpha bravo charly")', {}, 'UPPER("alpha bravo charly")' ],
  [ 'LOWER("ALPHA BRAVO Charly")', {}, 'LOWER("ALPHA BRAVO Charly")' ],

  [ 'LN(3044.31)', {}, 'LN(3044.31)' ],
  [ 'SQRT(260)', {}, 'SQRT(260)' ],
  [ 'SQRT({ 260, 81 })', {}, 'SQRT({260,81})' ],

  [ 'STDEV(a)', { 'a' => [ 10, 11 ] }, 'STDEV(a:{10,11})' ],

  [ '0.45 * we_c - 0.15 * it_c + 0.15 * sm_c + 0.25 * gp_c',
    { 'we_c' => 1.1, 'it_c' => 2.2, 'sm_c' => 3.3, 'gp_c' => 4.4 },
    '((0.45 * we_c:1.10) + (- (0.15 * it_c:2.20)) + ' +
    '(0.15 * sm_c:3.30) + (0.25 * gp_c:4.40))' ]
]

