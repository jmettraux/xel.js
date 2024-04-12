
#
# spec/_xel.rb

[
{ c: "987",
  t: ["num","987"], o: 987 },
{ c: "3,000,000",
  t: ["num","3,000,000"], o: 3000000 },
{ c: "123.45",
  t: ["num","123.45"], o: 123.45 },
{ c: "9,090.10",
  t: ["num","9,090.10"], o: 9090.1 },
{ c: ".123",
  t: ["num",".123"], o: 0.123 },
{ c: "-987",
  t: ["num","-987"], o: -987 },
{ c: "-3,000,000",
  t: ["num","-3,000,000"], o: -3000000 },
{ c: "-123.45",
  t: ["num","-123.45"], o: -123.45 },
{ c: "-9,090.10",
  t: ["num","-9,090.10"], o: -9090.1 },
{ c: "-.123",
  t: ["num","-.123"], o: -0.123 },
{ c: "\"12\" =~ \"[a-z]\"", o: false },
{ c: "\"a\" != \"a\"", o: false },
{ c: "\"a\" != \"b\"", o: true },
{ c: "\"a\" = \"a\"", o: true },
{ c: "\"a\" = \"b\"", o: false },
{ c: "\"a\" IN { \"alpha\", \"bravo\" }",
  t: ["cmp","IN",["str","a"],["arr",["str","alpha"],["str","bravo"]]] },
{ c: "\"a\" IN { 0, \"a\", 2 }", o: true },
{ c: "\"a\" IN { 0, \"b\", 2 }", o: false },
{ c: "\"a\" IN {}", o: false },
{ c: "\"ab\" =~ \"[a-z]\"", o: true },
{ c: "\"ab\\\"cd'ef\"", o: "ab\"cd'ef",t: ["str","ab\"cd'ef"] },
{ c: "\"b\" IN a", ctx: {"a":["a","b","c"]}, o: true },
{ c: "\"d\" IN a", ctx: {"a":["a","b","c"]}, o: false },
{ c: "'ab\"cd\\'ef'", o: "ab\"cd'ef",t: ["str","ab\"cd'ef"] },
{ c: "'ab' =~ '[a-z]'",
  t: ["cmp","=~",["str","ab"],["str","[a-z]"]] },
{ c: "(10 + 11) * 12",
  t: ["MUL",["plus",["num","10"],["num","11"]],["num","12"]] },
{ c: "0.45 * we_c - 0.15 * it_c + 0.15 * sm_c + 0.25 * gp_c", ctx: {"we_c":1.1,"it_c":2.2,"sm_c":3.3,"gp_c":4.4}, o: 1.76,t: ["plus",["MUL",["num","0.45"],["var","we_c"]],["opp",["MUL",["num","0.15"],["var","it_c"]]],["MUL",["num","0.15"],["var","sm_c"]],["MUL",["num","0.25"],["var","gp_c"]]] },
{ c: "1 * 2 + 3",
  t: ["plus",["MUL",["num","1"],["num","2"]],["num","3"]] },
{ c: "1 + \"a\"", o: "1a" },
{ c: "1 + 2", o: 3 },
{ c: "1 + 2 * 3",
  t: ["plus",["num","1"],["MUL",["num","2"],["num","3"]]] },
{ c: "1 + 2 < 3",
  t: ["cmp","<",["plus",["num","1"],["num","2"]],["num","3"]] },
{ c: "1 + a",
  t: ["plus",["num","1"],["var","a"]] },
{ c: "1 + a.b.c", ctx: {"a":{"b":{"c":66}}}, o: 67,t: ["plus",["num","1"],["var","a.b.c"]] },
{ c: "1 + v0", ctx: {"v0":70}, o: 71 },
{ c: "1 - -2", o: 3 },
{ c: "1 - 2", o: -1 },
{ c: "1 / 5", o: 0.2 },
{ c: "\"a\" & \"bc\"", o: "abc",t: ["amp",["str","a"],["str","bc"]] },
{ c: "1 & 1", o: "11",t: ["amp",["num","1"],["num","1"]] },
{ c: "\"ab\" & c & d & \"ef\"", ctx: {"c":"c"}, o: "abcef" },
{ c: "1 < 2", o: true },
{ c: "1 <= 2", o: true },
{ c: "1 > 2", o: false },
{ c: "1 IN a", ctx: {"a":[0,1,2]}, o: true },
{ c: "1 IN { 0, 1 }", o: true },
{ c: "1.0 / 5", o: 0.2 },
{ c: "10",
  t: ["num","10"] },
{ c: "10 + 11",
  t: ["plus",["num","10"],["num","11"]] },
{ c: "10 + 11 * 12",
  t: ["plus",["num","10"],["MUL",["num","11"],["num","12"]]] },
{ c: "10 + IF(ntac='no', 10, 0)",
  t: ["plus",["num","10"],["IF",["cmp","=",["var","ntac"],["str","no"]],["num","10"],["num","0"]]] },
{ c: "10 + SUM(1, 2)",
  t: ["plus",["num","10"],["SUM",["num","1"],["num","2"]]] },
{ c: "10 - -11",
  t: ["plus",["num","10"],["opp",["num","-11"]]] },
{ c: "10 / -11",
  t: ["MUL",["num","10"],["inv",["num","-11"]]] },
{ c: "12.3",
  t: ["num","12.3"] },
{ c: "2 != 3", o: true },
{ c: "2 <= 2", o: true },
{ c: "2 = 3", o: false },
{ c: "2 >= 2", o: true },
{ c: "2 >= 3", o: false },
{ c: "3 != 3", o: false },
{ c: "3 <= 2", o: false },
{ c: "3 = 3", o: true },
{ c: "3 >= 2", o: true },
{ c: "AND(\n        NOT(apac_currency),\n        OR(cm_rating_top_out_or_sector, jpm_overweight_or_neutral),\n        moat_narrow_or_wide)", ctx: {"apac_currency":true,"cm_rating_top_out_or_sector":true,"jpm_overweight_or_neutral":false,"moat_narrow_or_wide":false}, o: false },
{ c: "AND(\n        NOT(meta.apac_currency),\n        OR(meta.cm_rating_top_out_or_sector, meta.jpm_overweight_or_neutral),\n        meta.moat_narrow_or_wide)", ctx: {"meta":{"apac_currency":false,"cm_rating_top_out_or_sector":true,"jpm_overweight_or_neutral":false,"moat_narrow_or_wide":true}}, o: true },
{ c: "AND(\n        meta.apac_currency,\n        OR(meta.ms_rating_overall_543, meta.jpm_overweight_or_neutral),\n        meta.moat_narrow_or_wide,\n        meta.esg_risk_low_medium_or_negligible,\n        NOT(AND(meta.ms_rating_overall_3, meta.jpm_neutral)))", ctx: {"meta":{"apac_currency":true,"ms_rating_overall_3":false,"ms_rating_overall_543":true,"moat_narrow_or_wide":true,"esg_risk_low_medium_or_negligible":true}}, o: true },
{ c: "AND(FALSE())", o: false },
{ c: "AND(TRUE())", o: true },
{ c: "AND(TRUE(), FALSE())", o: false },
{ c: "AND(TRUE(), TRUE())", o: true },
{ c: "CASE(AND(a > 99, 2 > 1), 2, a > 9, 1, -1)", ctx: {"a":100}, o: 2 },
{ c: "CASE(a > 99, 2, a > 9, 1)", ctx: {"a":7}, o: nil },
{ c: "CASE(a > 99, 2, a > 9, 1, -1)", ctx: {"a":100}, o: 2 },
{ c: "CASE(eb, \"&\", 10, \"g\", 11, \"a\", 12)", ctx: {"eb":"X"}, o: nil },
{ c: "CASE(eb, \"&\", 10, \"g\", 11, \"a\", 12, 13)", ctx: {"eb":"nada"}, o: 13 },
{ c: "COUNTA(a)", ctx: {"a":[]}, o: 0 },
{ c: "COUNTA(a)", ctx: {"a":[1,2,3]}, o: 3 },
{ c: "FALSE()", o: false },
{ c: "HAS(a, \"b\")", ctx: {"a":["a","b","c"]}, o: true },
{ c: "HAS(a, \"d\")", ctx: {"a":["a","b","c"]}, o: false },
{ c: "HAS(a, 1)", ctx: {"a":[0,1,2]}, o: true },
{ c: "IF(FALSE(), 1, 2)", o: 2 },
{ c: "IF(TRUE(), 1, 2)", o: 1 },
{ c: "IF(f, 1, 2)", ctx: {"f":false}, o: 2 },
{ c: "IF(ntac='no', 10, 0)",
  t: ["IF",["cmp","=",["var","ntac"],["str","no"]],["num","10"],["num","0"]] },
{ c: "IF(t, 1, 2)", ctx: {"t":true}, o: 1 },
{ c: "INDEX(a, -1)", ctx: {"a":[0,1,2,"trois"]}, o: "trois" },
{ c: "INDEX(a, -2)", ctx: {"a":[0,1,2,"trois"]}, o: 2 },
{ c: "INDEX(a, 1)", ctx: {"a":[0,1,2]}, o: 0 },
{ c: "INDEX(a, 2)", ctx: {"a":[0,1,2]}, o: 1 },
{ c: "INDEX(a, COUNTA(a))", ctx: {"a":[0,"two"]}, o: "two" },
{ c: "ISBLANK(a)", ctx: {"a":"abc"}, o: false },
{ c: "ISBLANK(a)", ctx: {"a":""}, o: true },
{ c: "ISBLANK(a)", ctx: {}, o: true },
{ c: "ISNUMBER(\"nada\")", o: false },
{ c: "ISNUMBER(123)", o: true },
{ c: "ISNUMBER(123.12)", o: true },
{ c: "ISNUMBER(FALSE())", o: false },
{ c: "ISNUMBER(TRUE())", o: false },
{ c: "ISNUMBER(a)", ctx: {"a":nil}, o: false },
{ c: "LN(3044.31)", o: 8.02 },
{ c: "LN(a)", ctx: {"a":[3044.31,3047.12]}, o: [8.02,8.02] },
{ c: "LN({ 3044.31, 3047.12 })", o: [8.02,8.02] },
{ c: "MATCH(\"b\", a, 0)", ctx: {"a":["a","b","c"]}, o: 1 },
{ c: "MATCH(\"d\", a, 0)", ctx: {"a":["a","b"]}, o: -1 },
{ c: "MATCH(1, a, 0)", ctx: {"a":[0,1,2]}, o: 1 },
{ c: "MAX(-1, -2, \"a\", -3)", o: -1 },
{ c: "MAX(-1, -2, -3)", o: -1 },
{ c: "MAX(1, 2, 3)", o: 3 },
{ c: "MIN(-1, -2, \"a\", -3)", o: -1 },
{ c: "MIN(-1, -2, -3)", o: -3 },
{ c: "MIN(1, 2, 3)", o: 1 },
{ c: "NOT(FALSE())", o: true },
{ c: "NOT(TRUE())", o: false },
{ c: "OR(1 = 2, 2 = 2)", o: true },
{ c: "OR(1 = 2, 2 = 3)", o: false },
{ c: "OR(TRUE(), FALSE())", o: true },
{ c: "PRODUCT(2, 3, 4)", o: 24 },
{ c: "PRODUCT({ 2, 3, 4 })", o: 24 },
{ c: "PRODUCT({ 2, 3, 4 }, 2)", o: 48 },
{ c: "PRODUCT({ 2, 3, 4 }, a, 2)", ctx: {"a":[0.5,0.5]}, o: 12 },
{ c: "PROPER(\"alpha bravo charly\")", o: "Alpha Bravo Charly" },
{ c: "SORT({ 1, \"aa\", 7, 2 }, 1, -1)", o: ["aa",7,2,1] },
{ c: "SORT({ 1, 3, 2 })", o: [1,2,3] },
{ c: "SORT({ 1, 3, 2 }, 1, -1)", o: [3,2,1] },
{ c: "SQRT(260)", o: 16.1245 },
{ c: "SQRT(a)", ctx: {"a":[260,81]}, o: [16.1245,9] },
{ c: "SQRT({ 260, 81 })", o: [16.1245,9] },
{ c: "STDEV(a)", ctx: {"a":[10,11]}, o: 0.71 },
{ c: "SUM(1 + 2, 3, SUM(4, 5))",
  t: ["SUM",["plus",["num","1"],["num","2"]],["num","3"],["SUM",["num","4"],["num","5"]]] },
{ c: "SUM(2, 3, 4)", o: 9 },
{ c: "SUM(3,000,000, 2)",
  t: ["SUM",["num","3,000,000"],["num","2"]] },
{ c: "SUM({ 2, 3, 4 })", o: 9 },
{ c: "SUM({ 2, 3, 4 }, 2)", o: 11 },
{ c: "SUM({ 2, 3, 4 }, a, 2)", ctx: {"a":[0.5,0.5]}, o: 12 },
{ c: "SWITCH(eb, \"&\", 10, \"g\", 11, \"a\", 12)", ctx: {"eb":"X"}, o: nil },
{ c: "TRUE()", o: true },
{ c: "UNIQUE(a)", ctx: {"a":[1,2,1,1,2,3]}, o: [1,2,3] },
{ c: "UNIQUE({ 1, 1 })", o: [1] },
{ c: "UPPER(\"alpha bravo charly\")", o: "ALPHA BRAVO CHARLY" },
{ c: "LOWER(\"ALPHA BRAVO Charly\")", o: "alpha bravo charly" },
{ c: "a != \"\"", ctx: {"a":"abc"}, o: true },
{ c: "a = \"\"", ctx: {"a":"abc"}, o: false },
{ c: "{ 1, 2, 3 } + { 3, 4, 5 }",
  t: ["plus",["arr",["num","1"],["num","2"],["num","3"]],["arr",["num","3"],["num","4"],["num","5"]]] },
{ c: "ntac = \"yes\"", ctx: {"ntac":"no"}, o: false },
{ c: "ntac = 'no'",
  t: ["cmp","=",["var","ntac"],["str","no"]] },
{ c: "{1,\"a\", \"b\", 2, 0, \"d\" }",
  t: ["arr",["num","1"],["str","a"],["str","b"],["num","2"],["num","0"],["str","d"]] },
{ c: "LAMBDA(a, b, a + b)", o: {},t: ["LAMBDA",["var","a"],["var","b"],["plus",["var","a"],["var","b"]]] },
{ c: "KALL(LAMBDA(a, b, a + b), 7, -3)", o: 4 },
{ c: "KALL(LAMBDA(a, b, a + b), 7, -2, 1)", o: 5 },
{ c: "MAP({ 2, 3, 4 }, LAMBDA(a, 2 * a))", o: [4,6,8] },
{ c: "REDUCE(0, { 2, 3, 4 }, LAMBDA(a, e, a + e))", o: 9 },
{ c: "REDUCE({ 2, 3, 5 }, LAMBDA(a, e, a + e))", o: 10 },
{ c: "ORV('', '', 1)", o: 1 },
{ c: "ORV('', b, a, 3)", ctx: {"a":2}, o: 2 },
{ c: "ORV('', a, b, c)", ctx: {}, o: nil },
{ c: "TEXTJOIN(\"/\", TRUE(), \"a\", \"b\")", o: "a/b" },
{ c: "TEXTJOIN(\", \", TRUE(), a, \"zz\")", ctx: {"a":["ab","cd","ef1"]}, o: "ab, cd, ef1, zz" },
{ c: "TEXTJOIN(\", \", TRUE(), a, \"zz\")", ctx: {"a":["ab","","ef1"]}, o: "ab, ef1, zz" },
{ c: "TEXTJOIN(\", \", FALSE(), a, \"zz\")", ctx: {"a":["ab","","ef1"]}, o: "ab, , ef1, zz" },

{ c: "LET(l, LAMBDA(a, b, a + b), l(2, 3))",
  t: ["LET",["var","l"],["LAMBDA",["var","a"],["var","b"],["plus",["var","a"],["var","b"]]],["l",["num","2"],["num","3"]]] },
]
