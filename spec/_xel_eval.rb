
#
# spec'ing Xel
#
# Fri Sep 25 14:04:57 JST 2015
#

[
  [ '1 + 2', {}, 3 ],
  [ '1 - 2', {}, -1 ],
  [ '1 - -2', {}, 3 ],
  [ '1 / 5', {}, 0.2 ],
  [ '1.0 / 5', {}, 0.2 ],
  [ '1 + "a"', {}, '1a' ],

  [ '1 + v0', { v0: 70 }, 71 ],
  [ '1 + a.b.c', { a: { b: { c: 66 } } }, 67 ],

  [ '1 < 2', {}, true ],
  [ '1 > 2', {}, false ],
  [ '1 <= 2', {}, true ],
  [ '2 <= 2', {}, true ],
  [ '2 >= 2', {}, true ],
  [ '3 >= 2', {}, true ],
  [ '3 <= 2', {}, false ],
  [ '2 >= 3', {}, false ],
  [ '2 = 3', {}, false ],
  [ '3 = 3', {}, true ],
  [ '2 != 3', {}, true ],
  [ '3 != 3', {}, false ],
  [ '"a" = "a"', {}, true ],
  [ '"a" = "b"', {}, false ],
  [ '"a" != "a"', {}, false ],
  [ '"a" != "b"', {}, true ],

  [ '{ "a" } = { "a" }', {}, true ],
  [ '{ "a" } = { "b" }', {}, false ],
  [ '{ "a" } != { "b" }', {}, true ],
  [ '{ "a" } != { "a" }', {}, false ],
  [ '{ "a", "b" } != { "a" }', {}, true ],
  [ '{ "a", "b" } = { "a" }', {}, false ],
  [ '{ "a", "b" } = { "a", "b" }', {}, true ],
  [ '{ "a", "b" } != { "a", "b" }', {}, false ],

  [ '"ab" =~ "[a-z]"', {}, true ],
  [ '"12" =~ "[a-z]"', {}, false ],

  [ 'TRUE()', {}, true ],
  [ 'FALSE()', {}, false ],
  [ 'IF(FALSE(), 1, 2)', {}, 2 ],
  [ 'IF(TRUE(), 1, 2)', {}, 1 ],
  [ 'IF(t, 1, 2)', { t: true }, 1 ],
  [ 'IF(f, 1, 2)', { f: false }, 2 ],

  [ 'AND(TRUE())', {}, true ],
  [ 'AND(FALSE())', {}, false ],
  [ 'AND(TRUE(), TRUE())', {}, true ],
  [ 'AND(TRUE(), FALSE())', {}, false ],
  [ 'OR(TRUE(), FALSE())', {}, true ],
  [ 'NOT(TRUE())', {}, false ],
  [ 'NOT(FALSE())', {}, true ],

  [ 'OR(1 = 2, 2 = 3)', {}, false ],
  [ 'OR(1 = 2, 2 = 2)', {}, true ],

  [ %{
      AND(
        NOT(apac_currency),
        OR(cm_rating_top_out_or_sector, jpm_overweight_or_neutral),
        moat_narrow_or_wide)
    }.strip,
    {
      'apac_currency' => true,
      'cm_rating_top_out_or_sector' => true,
      'jpm_overweight_or_neutral' => false,
      'moat_narrow_or_wide' => false
    },
    false ],
  [ %{
      AND(
        NOT(meta.apac_currency),
        OR(meta.cm_rating_top_out_or_sector, meta.jpm_overweight_or_neutral),
        meta.moat_narrow_or_wide)
    }.strip,
    {
      'meta' => {
        'apac_currency' => false,
        'cm_rating_top_out_or_sector' => true,
        'jpm_overweight_or_neutral' => false,
        'moat_narrow_or_wide' => false }
    },
    false ],
  [ %{
      AND(
        NOT(meta.apac_currency),
        OR(meta.cm_rating_top_out_or_sector, meta.jpm_overweight_or_neutral),
        meta.moat_narrow_or_wide)
    }.strip,
    {
      'meta' => {
        'apac_currency' => false,
        'cm_rating_top_out_or_sector' => true,
        'jpm_overweight_or_neutral' => false,
        'moat_narrow_or_wide' => true }
    },
    true ],
  [ %{
      AND(
        meta.apac_currency,
        OR(meta.ms_rating_overall_543, meta.jpm_overweight_or_neutral),
        meta.moat_narrow_or_wide,
        meta.esg_risk_low_medium_or_negligible,
        NOT(AND(meta.ms_rating_overall_3, meta.jpm_neutral)))
    }.strip,
    {
      'meta' => {
        'apac_currency' => true,
        'ms_rating_overall_3' => false,
        'ms_rating_overall_543' => true,
        'moat_narrow_or_wide' => true,
        'esg_risk_low_medium_or_negligible' => true }
    },
    true ],

  [ 'ISBLANK(a)', {}, true ],
  [ 'ISBLANK(a)', { 'a' => '' }, true ],
  [ 'ISBLANK(a)', { 'a' => 'abc' }, false ],

  [ 'ISNUMBER(a)', {}, false ],
  [ 'ISNUMBER(a)', { 'a' => nil }, false ],
  [ 'ISNUMBER("nada")', {}, false ],
  [ 'ISNUMBER(TRUE())', {}, false ],
  [ 'ISNUMBER(FALSE())', {}, false ],
  [ 'ISNUMBER(123)', {}, true ],
  [ 'ISNUMBER(123.12)', {}, true ],

  [ 'a = ""', {}, true ],
  [ 'a = ""', { 'a' => '' }, true ],
  [ 'a = ""', { 'a' => true }, false ],
  [ 'a = ""', { 'a' => 'abc' }, false ],
  [ 'a != ""', {}, false ],
  [ 'a != ""', { 'a' => true }, true ],
  [ 'a != ""', { 'a' => '' }, false ],
  [ 'a != ""', { 'a' => 'abc' }, true ],

  [ 'ntac = "yes"', { 'ntac' => 'yes' }, true ],
  [ 'ntac = "yes"', { 'ntac' => 'no' }, false ],

  [ 'CASE(eb, "&", 10, "g", 11, "a", 12, 13)', { 'eb' => '&' }, 10 ],
  [ 'CASE(eb, "&", 10, "g", 11, "a", 12, 13)', { 'eb' => 'g' }, 11 ],
  [ 'CASE(eb, "&", 10, "g", 11, "a", 12, 13)', { 'eb' => 'a' }, 12 ],
  [ 'CASE(eb, "&", 10, "g", 11, "a", 12, 13)', { 'eb' => 'X' }, 13 ],
  [ 'CASE(eb, "&", 10, "g", 11, "a", 12)', { 'eb' => 'X' }, nil ],
  [ 'CASE(a > 99, 2, a > 9, 1)', { 'a' => 7 }, nil ],
  [ 'CASE(a > 99, 2, a > 9, 1, -1)', { 'a' => 7 }, -1 ],
  [ 'CASE(a > 99, 2, a > 9, 1, -1)', { 'a' => 10 }, 1 ],
  [ 'CASE(a > 99, 2, a > 9, 1, -1)', { 'a' => 100 }, 2 ],
  [ 'CASE(AND(a > 99, 2 > 1), 2, a > 9, 1, -1)', { 'a' => 100 }, 2 ],
  [ 'SWITCH(eb, "&", 10, "g", 11, "a", 12)', { 'eb' => 'X' }, nil ],

  [ 'MAX(1, 2, 3)', {}, 3 ],
  [ 'MAX(-1, -2, -3)', {}, -1 ],
  [ 'MAX(-1, -2, "a", -3)', {}, -1 ],
  [ 'MIN(1, 2, 3)', {}, 1 ],
  [ 'MIN(-1, -2, -3)', {}, -3 ],
  [ 'MIN(-1, -2, "a", -3)', {}, -1 ],

  [ 'MATCH(1, a, 0)', { 'a' => [ 0, 1, 2 ] }, 1 ],
  [ 'MATCH("b", a, 0)', { 'a' => %w[ a b c ] }, 1 ],
  [ 'MATCH("d", a, 0)', { 'a' => %w[ a b c ] }, -1 ],
  [ 'HAS(a, 1)', { 'a' => [ 0, 1, 2 ] }, true ],
  [ 'HAS(a, "b")', { 'a' => %w[ a b c ] }, true ],
  [ 'HAS(a, "d")', { 'a' => %w[ a b c ] }, false ],

  [ '1 IN a', { 'a' => [ 0, 1, 2 ] }, true ],
  [ '"b" IN a', { 'a' => %w[ a b c ] }, true ],
  [ '"d" IN a', { 'a' => %w[ a b c ] }, false ],
  [ '1 IN { 0, 1 }', {}, true ],
  [ '"a" IN { 0, "a", 2 }', {}, true ],
  [ '"a" IN { 0, "b", 2 }', {}, false ],
  [ '"a" IN {}', {}, false ],

  [ "'ab\"cd\\'ef'", {}, "ab\"cd'ef" ],
  [ "\"ab\\\"cd'ef\"", {}, "ab\"cd'ef" ],

  [ '{"a","b"}', {}, %w[ a b ] ],
  [ '{"a", "b", "c" } ', {}, %w[ a b c ] ],
  [ '{ 1, "a", "b", "c" } ', {}, [ 1, 'a', 'b', 'c' ] ],
  [ '{ 1, 2 } + { "a", "b" }', {}, [ 1, 2, 'a', 'b' ] ],

  [ '{ { "a", "b" }, { "c", "de" } }', {}, [ %w[ a b ], %w[ c de ] ] ],
  [ '{ { "a", 1 }, { "c", 2 } }', {}, [ [ 'a', 1 ], [ 'c', 2 ] ] ],

  [ 'INDEX(a, 1)', { 'a' => [ 0, 1, 2 ] }, 0 ],
  [ 'INDEX(a, 2)', { 'a' => [ 0, 1, 2 ] }, 1 ],
  [ 'COUNTA(a)', { 'a' => [] }, 0 ],
  [ 'COUNTA(a)', { 'a' => [ 0, 1, 2 ] }, 3 ],
  [ 'INDEX(a, COUNTA(a))', { 'a' => [ 0, 1, 'two' ] }, 'two' ],
  [ 'INDEX(a, -1)', { 'a' => [ 0, 1, 2, 'trois' ] }, 'trois' ],
  [ 'INDEX(a, -2)', { 'a' => [ 0, 1, 2, 'trois' ] }, 2 ],
  [ 'UNIQUE({ 1, 1 })', {}, [ 1 ] ],
  [ 'UNIQUE(a)', { 'a' => [ 1, 2, 1, 1, 2, 3 ] }, [ 1, 2, 3 ] ],

  # ```excel
  # =SORT(array, [sort_index], [sort_order], [by_col])
  # ```
  #
  # - "array" is the range or array which you want to sort.
  # - "sort_index" is an optional argument representing the index of the column
  #   or row within the array that you want to sort by. Default is 1.
  # - "sort_order" is an optional argument: 1 for ascending (Default), -1 for
  #   descending.
  # - "by_col" is an optional logical value: TRUE sorts by column, FALSE or
  #   omitted sorts by row.
  #
  [ 'SORT({ 1, 3, 2 })', {}, [ 1, 2, 3 ] ],
  [ 'SORT({ 1, 3, 2 }, 1, -1)', {}, [ 3, 2, 1 ] ],
  [ 'SORT({ 1, "aa", 7, 2 }, 1, -1)', {}, [ "aa", 7, 2, 1 ] ],

  [ 'PROPER("alpha bravo charly")', {}, 'Alpha Bravo Charly' ],
  [ 'UPPER("alpha bravo charly")', {}, 'ALPHA BRAVO CHARLY' ],
  [ 'LOWER("ALPHA BRAVO Charly")', {}, 'alpha bravo charly' ],

  [ 'LN(3044.31)', {}, 8.02 ],
  [ 'LN(a)', { 'a' => [ 3044.31, 3047.12 ] }, [ 8.02, 8.02 ] ],
  [ 'LN({ 3044.31, 3047.12 })', {}, [ 8.02, 8.02 ] ],
  [ 'SQRT(260)', {}, 16.1245 ],
  [ 'SQRT(a)', { 'a' => [ 260, 81 ] }, [ 16.1245, 9 ] ],
  [ 'SQRT({ 260, 81 })', {}, [ 16.1245, 9 ] ],

  [ 'STDEV(a)', { 'a' => [ 10, 11, 20, 34, 67 ] }, 23.62837 ],

  [ '0.45 * we_c - 0.15 * it_c + 0.15 * sm_c + 0.25 * gp_c',
    { 'we_c' => 1.1, 'it_c' => 2.2, 'sm_c' => 3.3, 'gp_c' => 4.4 },
    1.76 ],

  [ 'PRODUCT(2, 3, 4)', {}, 24 ],
  [ 'PRODUCT({ 2, 3, 4 })', {}, 24 ],
  [ 'PRODUCT({ 2, 3, 4 }, 2)', {}, 48 ],
]

