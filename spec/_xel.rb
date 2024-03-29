
## >"12" =~ "[a-z]"<
{
  ctx:    {},
  out:    false,
  peval:  "(\"12\" =~ \"[a-z]\")",
}

## >"a" != "a"<
{
  ctx:    {},
  out:    false,
}

## >"a" != "b"<
{
  ctx:    {},
  out:    true,
  peval:  "(\"a\" != \"b\")",
}

## >"a" = "a"<
{
  ctx:    {},
  out:    true,
}

## >"a" = "b"<
{
  ctx:    {},
  out:    false,
  peval:  "(\"a\" = \"b\")",
}

## >"a" IN { "alpha", "bravo" }<
{
  tree:   ["cmp", "IN", ["str", "a"], ["arr", ["str", "alpha"], ["str", "bravo"]]],
}

## >"a" IN { 0, "a", 2 }<
{
  ctx:    {},
  out:    true,
  peval:  "(\"a\" IN {0,\"a\",2})",
}

## >"a" IN { 0, "b", 2 }<
{
  ctx:    {},
  out:    false,
}

## >"a" IN {}<
{
  ctx:    {},
  out:    false,
  peval:  "(\"a\" IN {})",
}

## >"ab" =~ "[a-z]"<
{
  ctx:    {},
  out:    true,
  peval:  "(\"ab\" =~ \"[a-z]\")",
}

## >"ab\"cd'ef"<
{
  ctx:    {},
  out:    "ab\"cd'ef",
  peval:  "\"ab\\\"cd'ef\"",
  tree:   ["str", "ab\"cd'ef"],
}

## >"b" IN a<
{
  ctx:    {"a"=>["a", "b", "c"]},
  out:    true,
  peval:  "(\"b\" IN a:{\"a\",\"b\",\"c\"})",
}

## >"d" IN a<
{
  ctx:    {"a"=>["a", "b", "c"]},
  out:    false,
}

## >'ab"cd\'ef'<
{
  ctx:    {},
  out:    "ab\"cd'ef",
  peval:  "\"ab\\\"cd'ef\"",
  tree:   ["str", "ab\"cd'ef"],
}

## >'ab' =~ '[a-z]'<
{
  tree:   ["cmp", "=~", ["str", "ab"], ["str", "[a-z]"]],
}

## >(10 + 11) * 12<
{
  tree:   ["MUL", ["plus", ["num", "10"], ["num", "11"]], ["num", "12"]],
}

## >0.45 * we_c - 0.15 * it_c + 0.15 * sm_c + 0.25 * gp_c<
{
  ctx:    {"we_c"=>1.1, "it_c"=>2.2, "sm_c"=>3.3, "gp_c"=>4.4},
  out:    1.76,
  peval:  "((0.45 * we_c:1.10) + (- (0.15 * it_c:2.20)) + (0.15 * sm_c:3.30) + (0.25 * gp_c:4.40))",
  tree:   ["plus", ["MUL", ["num", "0.45"], ["var", "we_c"]], ["opp", ["MUL", ["num", "0.15"], ["var", "it_c"]]], ["MUL", ["num", "0.15"], ["var", "sm_c"]], ["MUL", ["num", "0.25"], ["var", "gp_c"]]],
}

## >1 * 2 + 3<
{
  tree:   ["plus", ["MUL", ["num", "1"], ["num", "2"]], ["num", "3"]],
}

## >1 + "a"<
{
  ctx:    {},
  out:    "1a",
  peval:  "(1 + \"a\")",
}

## >1 + 2<
{
  ctx:    {},
  out:    3,
  peval:  "(1 + 2)",
}

## >1 + 2 * 3<
{
  tree:   ["plus", ["num", "1"], ["MUL", ["num", "2"], ["num", "3"]]],
}

## >1 + 2 < 3<
{
  tree:   ["cmp", "<", ["plus", ["num", "1"], ["num", "2"]], ["num", "3"]],
}

## >1 + a<
{
  tree:   ["plus", ["num", "1"], ["var", "a"]],
}

## >1 + a.b.c<
{
  ctx:    {:a=>{:b=>{:c=>66}}},
  out:    67,
  peval:  "(1 + a.b.c:66)",
  tree:   ["plus", ["num", "1"], ["var", "a.b.c"]],
}

## >1 + v0<
{
  ctx:    {:v0=>70},
  out:    71,
  peval:  "(1 + v0:70)",
}

## >1 - -2<
{
  ctx:    {},
  out:    3,
  peval:  "(1 + 2)",
}

## >1 - 2<
{
  ctx:    {},
  out:    -1,
  peval:  "(1 + (- 2))",
}

## >1 / 5<
{
  ctx:    {},
  out:    0.2,
  peval:  "(1 * (1 / 5))",
}

## >1 < 2<
{
  ctx:    {},
  out:    true,
  peval:  "(1 < 2)",
}

## >1 <= 2<
{
  ctx:    {},
  out:    true,
  peval:  "(1 <= 2)",
}

## >1 > 2<
{
  ctx:    {},
  out:    false,
  peval:  "(1 > 2)",
}

## >1 IN a<
{
  ctx:    {"a"=>[0, 1, 2]},
  out:    true,
  peval:  "(1 IN a:{0,1,2})",
}

## >1 IN { 0, 1 }<
{
  ctx:    {},
  out:    true,
  peval:  "(1 IN {0,1})",
}

## >1.0 / 5<
{
  ctx:    {},
  out:    0.2,
  peval:  "(1.0 * (1 / 5))",
}

## >10<
{
  tree:   ["num", "10"],
}

## >10 + 11<
{
  tree:   ["plus", ["num", "10"], ["num", "11"]],
}

## >10 + 11 * 12<
{
  tree:   ["plus", ["num", "10"], ["MUL", ["num", "11"], ["num", "12"]]],
}

## >10 + IF(ntac='no', 10, 0)<
{
  tree:   ["plus", ["num", "10"], ["IF", ["cmp", "=", ["var", "ntac"], ["str", "no"]], ["num", "10"], ["num", "0"]]],
}

## >10 + SUM(1, 2)<
{
  tree:   ["plus", ["num", "10"], ["SUM", ["num", "1"], ["num", "2"]]],
}

## >10 - -11<
{
  tree:   ["plus", ["num", "10"], ["opp", ["num", "-11"]]],
}

## >10 / -11<
{
  tree:   ["MUL", ["num", "10"], ["inv", ["num", "-11"]]],
}

## >12.3<
{
  tree:   ["num", "12.3"],
}

## >2 != 3<
{
  ctx:    {},
  out:    true,
}

## >2 <= 2<
{
  ctx:    {},
  out:    true,
}

## >2 = 3<
{
  ctx:    {},
  out:    false,
  peval:  "(2 = 3)",
}

## >2 >= 2<
{
  ctx:    {},
  out:    true,
  peval:  "(2 >= 2)",
}

## >2 >= 3<
{
  ctx:    {},
  out:    false,
}

## >3 != 3<
{
  ctx:    {},
  out:    false,
  peval:  "(3 != 3)",
}

## >3 <= 2<
{
  ctx:    {},
  out:    false,
}

## >3 = 3<
{
  ctx:    {},
  out:    true,
}

## >3 >= 2<
{
  ctx:    {},
  out:    true,
}

## >3,000,000<
{
  tree:   ["num", "3,000,000"],
}

## >AND(
        NOT(apac_currency),
        OR(cm_rating_top_out_or_sector, jpm_overweight_or_neutral),
        moat_narrow_or_wide)<
{
  ctx:    {"apac_currency"=>true, "cm_rating_top_out_or_sector"=>true, "jpm_overweight_or_neutral"=>false, "moat_narrow_or_wide"=>false},
  out:    false,
}

## >AND(
        NOT(meta.apac_currency),
        OR(meta.cm_rating_top_out_or_sector, meta.jpm_overweight_or_neutral),
        meta.moat_narrow_or_wide)<
{
  ctx:    {"meta"=>{"apac_currency"=>false, "cm_rating_top_out_or_sector"=>true, "jpm_overweight_or_neutral"=>false, "moat_narrow_or_wide"=>true}},
  out:    true,
}

## >AND(
        meta.apac_currency,
        OR(meta.ms_rating_overall_543, meta.jpm_overweight_or_neutral),
        meta.moat_narrow_or_wide,
        meta.esg_risk_low_medium_or_negligible,
        NOT(AND(meta.ms_rating_overall_3, meta.jpm_neutral)))<
{
  ctx:    {"meta"=>{"apac_currency"=>true, "ms_rating_overall_3"=>false, "ms_rating_overall_543"=>true, "moat_narrow_or_wide"=>true, "esg_risk_low_medium_or_negligible"=>true}},
  out:    true,
}

## >AND(FALSE())<
{
  ctx:    {},
  out:    false,
  peval:  "AND(FALSE())",
}

## >AND(TRUE())<
{
  ctx:    {},
  out:    true,
  peval:  "AND(TRUE())",
}

## >AND(TRUE(), FALSE())<
{
  ctx:    {},
  out:    false,
  peval:  "AND(TRUE(), FALSE())",
}

## >AND(TRUE(), TRUE())<
{
  ctx:    {},
  out:    true,
  peval:  "AND(TRUE(), TRUE())",
}

## >CASE(AND(a > 99, 2 > 1), 2, a > 9, 1, -1)<
{
  ctx:    {"a"=>100},
  out:    2,
  peval:  "CASE(AND((a:100 > 99), (2 > 1)), 2, (a:100 > 9), 1, -1)",
}

## >CASE(a > 99, 2, a > 9, 1)<
{
  ctx:    {"a"=>7},
  out:    nil,
  peval:  "CASE((a:7 > 99), 2, (a:7 > 9), 1)",
}

## >CASE(a > 99, 2, a > 9, 1, -1)<
{
  ctx:    {"a"=>100},
  out:    2,
  peval:  "CASE((a:100 > 99), 2, (a:100 > 9), 1, -1)",
}

## >CASE(eb, "&", 10, "g", 11, "a", 12)<
{
  ctx:    {"eb"=>"X"},
  out:    nil,
}

## >CASE(eb, "&", 10, "g", 11, "a", 12, 13)<
{
  ctx:    {"eb"=>"nada"},
  out:    13,
  peval:  "CASE(eb:\"nada\", \"&\", 10, \"g\", 11, \"a\", 12, 13)", # meh
}

## >COUNTA(a)<
{
  ctx:    {"a"=>[]},
  out:    0,
  peval:  "COUNTA(a:{})",
}

## >COUNTA(a)<
{
  ctx:    {"a"=>[1,2,3]},
  out:    3,
  peval:  "COUNTA(a:{1,2,3})",
}

## >FALSE()<
{
  ctx:    {},
  out:    false,
  peval:  "FALSE()",
}

## >HAS(a, "b")<
{
  ctx:    {"a"=>["a", "b", "c"]},
  out:    true,
  peval:  "HAS(a:{\"a\",\"b\",\"c\"}, \"b\")",
}

## >HAS(a, "d")<
{
  ctx:    {"a"=>["a", "b", "c"]},
  out:    false,
}

## >HAS(a, 1)<
{
  ctx:    {"a"=>[0, 1, 2]},
  out:    true,
  peval:  "HAS(a:{0,1,2}, 1)",
}

## >IF(FALSE(), 1, 2)<
{
  ctx:    {},
  out:    2,
  peval:  "IF(FALSE(), 1, 2)",
}

## >IF(TRUE(), 1, 2)<
{
  ctx:    {},
  out:    1,
  peval:  "IF(TRUE(), 1, 2)",
}

## >IF(f, 1, 2)<
{
  ctx:    {:f=>false},
  out:    2,
  peval:  "IF(f:false, 1, 2)",
}

## >IF(ntac='no', 10, 0)<
{
  tree:   ["IF", ["cmp", "=", ["var", "ntac"], ["str", "no"]], ["num", "10"], ["num", "0"]],
}

## >IF(t, 1, 2)<
{
  ctx:    {:t=>true},
  out:    1,
  peval:  "IF(t:true, 1, 2)",
}

## >INDEX(a, -1)<
{
  ctx:    {"a"=>[0, 1, 2, "trois"]},
  out:    "trois",
  peval:  "INDEX(a:{0,1,2,\"trois\"}, -1)",
}

## >INDEX(a, -2)<
{
  ctx:    {"a"=>[0, 1, 2, "trois"]},
  out:    2,
}

## >INDEX(a, 1)<
{
  ctx:    {"a"=>[0, 1, 2]},
  out:    0,
  peval:  "INDEX(a:{0,1,2}, 1)",
}

## >INDEX(a, 2)<
{
  ctx:    {"a"=>[0, 1, 2]},
  out:    1,
}

## >INDEX(a, COUNTA(a))<
{
  ctx:    {"a"=>[0, "two"]},
  out:    "two",
  peval:  "INDEX(a:{0,\"two\"}, COUNTA(a:{0,\"two\"}))",
}

## >ISBLANK(a)<
{
  ctx:    {"a"=>"abc"},
  out:    false,
  peval:  "ISBLANK(a:\"abc\")",
}

## >ISNUMBER("nada")<
{
  ctx:    {},
  out:    false,
  peval:  "ISNUMBER(\"nada\")",
}

## >ISNUMBER(123)<
{
  ctx:    {},
  out:    true,
  peval:  "ISNUMBER(123)",
}

## >ISNUMBER(123.12)<
{
  ctx:    {},
  out:    true,
  peval:  "ISNUMBER(123.12)",
}

## >ISNUMBER(FALSE())<
{
  ctx:    {},
  out:    false,
  peval:  "ISNUMBER(FALSE())",
}

## >ISNUMBER(TRUE())<
{
  ctx:    {},
  out:    false,
  peval:  "ISNUMBER(TRUE())",
}

## >ISNUMBER(a)<
{
  ctx:    {"a"=>nil},
  out:    false,
  peval:  "ISNUMBER(a:-)",
}

## >LN(3044.31)<
{
  ctx:    {},
  out:    8.02,
  peval:  "LN(3044.31)",
}

## >LN(a)<
{
  ctx:    {"a"=>[3044.31, 3047.12]},
  out:    [8.02, 8.02],
}

## >LN({ 3044.31, 3047.12 })<
{
  ctx:    {},
  out:    [8.02, 8.02],
}

## >LOWER("ALPHA BRAVO Charly")<
{
  ctx:    {},
  out:    "alpha bravo charly",
  peval:  "LOWER(\"ALPHA BRAVO Charly\")",
}

## >MATCH("b", a, 0)<
{
  ctx:    {"a"=>["a", "b", "c"]},
  out:    1,
}

## >MATCH("d", a, 0)<
{
  ctx:    {"a"=>["a", "b"]},
  out:    -1,
  peval:  "MATCH(\"d\", a:{\"a\",\"b\"}, 0)",
}

## >MATCH(1, a, 0)<
{
  ctx:    {"a"=>[0, 1, 2]},
  out:    1,
  peval:  "MATCH(1, a:{0,1,2}, 0)",
}

## >MAX(-1, -2, "a", -3)<
{
  ctx:    {},
  out:    -1,
}

## >MAX(-1, -2, -3)<
{
  ctx:    {},
  out:    -1,
}

## >MAX(1, 2, 3)<
{
  ctx:    {},
  out:    3,
}

## >MIN(-1, -2, "a", -3)<
{
  ctx:    {},
  out:    -1,
}

## >MIN(-1, -2, -3)<
{
  ctx:    {},
  out:    -3,
}

## >MIN(1, 2, 3)<
{
  ctx:    {},
  out:    1,
}

## >NOT(FALSE())<
{
  ctx:    {},
  out:    true,
  peval:  "NOT(FALSE())",
}

## >NOT(TRUE())<
{
  ctx:    {},
  out:    false,
  peval:  "NOT(TRUE())",
}

## >OR(1 = 2, 2 = 2)<
{
  ctx:    {},
  out:    true,
  peval:  "OR((1 = 2), (2 = 2))",
}

## >OR(1 = 2, 2 = 3)<
{
  ctx:    {},
  out:    false,
  peval:  "OR((1 = 2), (2 = 3))",
}

## >OR(TRUE(), FALSE())<
{
  ctx:    {},
  out:    true,
  peval:  "OR(TRUE(), FALSE())",
}

## >PRODUCT(2, 3, 4)<
{
  ctx:    {},
  out:    24,
  peval:  "PRODUCT(2, 3, 4)",
}

## >PRODUCT({ 2, 3, 4 })<
{
  ctx:    {},
  out:    24,
  peval:  "PRODUCT({2,3,4})",
}

## >PRODUCT({ 2, 3, 4 }, 2)<
{
  ctx:    {},
  out:    48,
  peval:  "PRODUCT({2,3,4}, 2)",
}

## >PRODUCT({ 2, 3, 4 }, a, 2)<
{
  ctx:    {"a"=>[0.5, 0.5]},
  out:    12,
  peval:  "PRODUCT({2,3,4}, a:{0.50,0.50}, 2)",
}

## >PROPER("alpha bravo charly")<
{
  ctx:    {},
  out:    "Alpha Bravo Charly",
  peval:  "PROPER(\"alpha bravo charly\")",
}

## >SORT({ 1, "aa", 7, 2 }, 1, -1)<
{
  ctx:    {},
  out:    ["aa", 7, 2, 1],
  peval:  "SORT({1,\"aa\",7,2}, 1, -1)",
}

## >SORT({ 1, 3, 2 })<
{
  ctx:    {},
  out:    [1, 2, 3],
  peval:  "SORT({1,3,2})",
}

## >SORT({ 1, 3, 2 }, 1, -1)<
{
  ctx:    {},
  out:    [3, 2, 1],
  peval:  "SORT({1,3,2}, 1, -1)",
}

## >SQRT(260)<
{
  ctx:    {},
  out:    16.1245,
  peval:  "SQRT(260)",
}

## >SQRT(a)<
{
  ctx:    {"a"=>[260, 81]},
  out:    [16.1245, 9],
}

## >SQRT({ 260, 81 })<
{
  ctx:    {},
  out:    [16.1245, 9],
  peval:  "SQRT({260,81})",
}

## >STDEV(a)<
{
  ctx:    {"a"=>[10, 11]},
  out:    0.71,
  peval:  "STDEV(a:{10,11})",
}

## >SUM(1 + 2, 3, SUM(4, 5))<
{
  tree:   ["SUM", ["plus", ["num", "1"], ["num", "2"]], ["num", "3"], ["SUM", ["num", "4"], ["num", "5"]]],
}

## >SUM(2, 3, 4)<
{
  ctx:    {},
  out:    9,
  peval:  "SUM(2, 3, 4)",
}

## >SUM(3,000,000, 2)<
{
  tree:   ["SUM", ["num", "3,000,000"], ["num", "2"]],
}

## >SUM({ 2, 3, 4 })<
{
  ctx:    {},
  out:    9,
  peval:  "SUM({2,3,4})",
}

## >SUM({ 2, 3, 4 }, 2)<
{
  ctx:    {},
  out:    11,
  peval:  "SUM({2,3,4}, 2)",
}

## >SUM({ 2, 3, 4 }, a, 2)<
{
  ctx:    {"a"=>[0.5, 0.5]},
  out:    12,
  peval:  "SUM({2,3,4}, a:{0.50,0.50}, 2)",
}

## >SWITCH(eb, "&", 10, "g", 11, "a", 12)<
{
  ctx:    {"eb"=>"X"},
  out:    nil,
}

## >TRUE()<
{
  ctx:    {},
  out:    true,
  peval:  "TRUE()",
}

## >UNIQUE(a)<
{
  ctx:    {"a"=>[1, 2, 1, 1, 2, 3]},
  out:    [1, 2, 3],
  peval:  "UNIQUE(a:{1,2,1,1,2,3})",
}

## >UNIQUE({ 1, 1 })<
{
  ctx:    {},
  out:    [1],
  peval:  "UNIQUE({1,1})",
}

## >UPPER("alpha bravo charly")<
{
  ctx:    {},
  out:    "ALPHA BRAVO CHARLY",
  peval:  "UPPER(\"alpha bravo charly\")",
}

## >a != ""<
{
  ctx:    {"a"=>"abc"},
  out:    true,
  peval:  "(a:\"abc\" != \"\")",
}

## >a = ""<
{
  ctx:    {"a"=>"abc"},
  out:    false,
  peval:  "(a:\"abc\" = \"\")",
}

## >ntac = "yes"<
{
  ctx:    {"ntac"=>"no"},
  out:    false,
  peval:  "(ntac:\"no\" = \"yes\")",
}

## >ntac = 'no'<
{
  tree:   ["cmp", "=", ["var", "ntac"], ["str", "no"]],
}

## >{ "a" } != { "a" }<
{
  ctx:    {},
  out:    false,
}

## >{ "a" } != { "b" }<
{
  ctx:    {},
  out:    true,
}

## >{ "a" } = { "a" }<
{
  ctx:    {},
  out:    true,
}

## >{ "a" } = { "b" }<
{
  ctx:    {},
  out:    false,
}

## >{ "a", "b" } != { "a" }<
{
  ctx:    {},
  out:    true,
}

## >{ "a", "b" } != { "a", "b" }<
{
  ctx:    {},
  out:    false,
}

## >{ "a", "b" } = { "a" }<
{
  ctx:    {},
  out:    false,
}

## >{ "a", "b" } = { "a", "b" }<
{
  ctx:    {},
  out:    true,
}

## >{ 1, "a", "b", "c" } <
{
  ctx:    {},
  out:    [1, "a", "b", "c"],
  peval:  "{1,\"a\",\"b\",\"c\"}",
}

## >{ 1, 2 } + { "a", "b" }<
{
  ctx:    {},
  out:    [1, 2, "a", "b"],
  peval:  "({1,2} + {\"a\",\"b\"})",
}

## >{ 1, 2, 3 } + { 3, 4, 5 }<
{
  tree:   ["plus", ["arr", ["num", "1"], ["num", "2"], ["num", "3"]], ["arr", ["num", "3"], ["num", "4"], ["num", "5"]]],
}

## >{ { "a", "b" }, { "c", "de" } }<
{
  ctx:    {},
  out:    [["a", "b"], ["c", "de"]],
}

## >{ { "a", 1 }, { "c", 2 } }<
{
  ctx:    {},
  out:    [["a", 1], ["c", 2]],
}

## >{"a", "b", "c" } <
{
  ctx:    {},
  out:    ["a", "b", "c"],
}

## >{"a","b"}<
{
  ctx:    {},
  out:    ["a", "b"],
}

## >{1,"a", "b", 2, 0, "d" }<
{
  tree:   ["arr", ["num", "1"], ["str", "a"], ["str", "b"], ["num", "2"], ["num", "0"], ["str", "d"]],
}
