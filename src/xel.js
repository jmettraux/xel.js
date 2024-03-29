
// xel.js

var XelParser = Jaabro.makeParser(function() {

  // parse

  function aa(i) { return rex(null, i, /\{\s*/); }
  function az(i) { return rex(null, i, /\}\s*/); }
  function pa(i) { return rex(null, i, /\(\s*/); }
  function pz(i) { return rex(null, i, /\)\s*/); }
  function com(i) { return rex(null, i, /,\s*/); }

  function number(i) {
    return rex('number', i, /-?([0-9]*\.[0-9]+|[0-9][,0-9]*[0-9]|[0-9]+)\s*/); }

  function va(i) { return rex('var', i, /[a-z_][A-Za-z0-9_.]*\s*/); }

  function arr(i) { return eseq('arr', i, aa, cmp, com, az); }

  function qstring(i) { return rex('qstring', i, /'(\\'|[^'])*'\s*/); }
  function dqstring(i) { return rex('dqstring', i, /"(\\"|[^"])*"\s*/); }
  function string(i) { return alt('string', i, dqstring, qstring); }

  function funargs(i) { return eseq('funargs', i, pa, cmp, com, pz); }
  function funname(i) { return rex('funname', i, /[A-Z][_a-zA-Z0-9]*/); }
  function fun(i) { return seq('fun', i, funname, funargs); }

  function comparator(i) {
    return rex('comparator', i, /([\<\>]=?|=~|!?=|IN)\s*/); }
  function multiplier(i) {
    return rex('multiplier', i, /[*\/]\s*/); }
  function adder(i) {
    return rex('adder', i, /[+\-]\s*/); }

  function par(i) { return seq('par', i, pa, cmp, pz); }
  function exp(i) { return alt('exp', i, par, fun, number, string, arr, va); }

  function mul(i) { return jseq('mul', i, exp, multiplier); }
  function add(i) { return jseq('add', i, mul, adder); }

  function rcmp(i) { return seq('rcmp', i, comparator, add); }
  function cmp(i) { return seq('cmp', i, add, rcmp, '?'); }

  var root = cmp;

  // rewrite

  function rewrite_cmp(t) {

    if (t.children.length === 1) return rewrite(t.children[0]);

    return [
      'cmp',
      t.children[1].children[0].string().trim(),
      rewrite(t.children[0]),
      rewrite(t.children[1].children[1])
    ];
  }

  function rewrite_add(t) {

    if (t.children.length === 1) return rewrite(t.children[0]);

    var cn = t.children.slice(); // dup array
    var a = [ t.name === 'add' ? 'plus' : 'MUL' ];
    var mod = null;
    var c = null;

    while (c = cn.shift()) {
      var v = rewrite(c);
      if (mod) v = [ mod, v ];
      a.push(v);
      c = cn.shift();
      if ( ! c) break;
      mod = { '-': 'opp', '/': 'inv' }[c.string().trim()];
    }

    return a;
  }
  var rewrite_mul = rewrite_add;

  function rewrite_fun(t) {

    var a = [ t.children[0].string() ];
    t.children[1].children.forEach(function(c) {
      if (c.name) a.push(rewrite(c));
    });

    return a;
  }

  function rewrite_exp(t) { return rewrite(t.children[0]); }

  function rewrite_par(t) { return rewrite(t.children[1]); }

  function rewrite_arr(t) {
    var a = [ 'arr' ];
    t.children.forEach(function(c) { if (c.name) a.push(rewrite(c)); });
    return a; }

  function rewrite_var(t) { return [ 'var', t.string().trim() ]; }
  function rewrite_number(t) { return [ 'num', t.string().trim() ]; }

  function rewrite_string(t) {

    var s = t.children[0].string().trim();
    var q = s[0];
    var s = s.slice(1, -1);

    return [
      'str', q === '"' ? s.replace(/\\\"/g, '"') : s.replace(/\\'/g, "'") ];
  }
}); // end XelParser


var Xel = (function() {

  "use strict";

  this.VERSION = '1.1.0';

  var self = this;

  //
  // protected functions

  // --- PEVALS

  var toS = function(v) {
    if (v === undefined || v === null)
      return '-';
    if (Array.isArray(v))
      return '{' + v.map(function(e) { return toS(e); }).join(',') + '}';
    if (typeof v == 'number') {
      var s = v.toFixed(2); if (s.match(/\.00$/)) s = v.toFixed(0);
      return s; }
    return JSON.stringify(v);
  };

  var pevals = {};

  pevals.plus = function(tree, context) {
    var es = tree.slice(1).map(function(t) { return self.peval(t, context); });
    return '(' + es.join(' + ') + ')';
  };
  pevals.num = function(tree, context) {
    return '' + tree[1];
  };
  pevals.var = function(tree, context) {
    return tree[1] + ':' + toS(evals.var(tree, context));
  };

  pevals.MUL = function(tree, context) {
    var es = tree.slice(1).map(function(t) { return self.peval(t, context); });
    return '(' + es.join(' * ') + ')';
  };

  pevals.inv = function(tree, context) {
    var c = self.peval(tree[1], context);
    return '(1 / ' + c + ')';
  };
  pevals.opp = function(tree, context) {
    var c = self.peval(tree[1], context);
    var m = c.match(/^-(.+)$/); if (m) return m[1];
    return '(- ' + c + ')';
  };

  pevals.arr = function(tree, context) {
    var s = '{';
    tree.slice(1).forEach(function(c) {
      s = s + (s.length > 1 ? ',' : '') + self.peval(c, context); });
    return s + '}';
    //return toS(
    //  tree.slice(1).map(function(c) { return self.peval(c, context); }));
  };

  pevals.str = function(tree, context) { return JSON.stringify(tree[1]); };

  pevals.cmp = function(tree, context) {
    var es = tree.slice(2).map(function(t) { return self.peval(t, context); });
    return '(' + es.join(' ' + tree[1] + ' ') + ')';
  };

  pevals._fun = function(tree, context) {
    var es = tree.slice(1).map(function(t) { return self.peval(t, context); });
    return tree[0] + '(' + es.join(', ') + ')';
  };

  pevals.TRUE = pevals._fun;
  pevals.FALSE = pevals._fun;

  pevals.IF = pevals._fun;

  pevals.CASE = pevals._fun;

  pevals.AND = pevals._fun;
  pevals.OR = pevals._fun;
  pevals.NOT = pevals._fun;

  pevals.MATCH = pevals._fun;
  pevals.HAS = pevals._fun;
  pevals.INDEX = pevals._fun;
  pevals.COUNTA = pevals._fun;
  pevals.ISBLANK = pevals._fun;
  pevals.ISNUMBER = pevals._fun;

  pevals.UNIQUE = pevals._fun;
  pevals.SORT = pevals._fun;

  pevals.PROPER = pevals._fun;

  pevals.LOWER = pevals._fun;
  pevals.UPPER = pevals._fun;

  pevals.LN = pevals._fun;
  pevals.SQRT = pevals._fun;
  pevals.STDEV = pevals._fun;

  pevals.SUM = pevals._fun;
  pevals.PRODUCT = pevals._fun;

  // --- EVALS

  var xtype = function(x) {

    return(
      x === null ? 'null' :
      Array.isArray(x) ? 'array' :
      (typeof x));
  };

  var evals = {};

  evals.var = function(tree, context) {

    var v = context;

    tree[1].split('.')
      .forEach(function(k) {
        if (v === undefined || v === null) return;
        v = v[k]; });

    return v;
  };

  evals.inv = function(tree, context) {
    return 1 / self.eval(tree[1], context);
  };
  evals.opp = function(tree, context) {
    return - self.eval(tree[1], context);
  };

  evals.str = function(tree, context) { return tree[1]; };

  evals.TRUE = function(tree, context) { return true; };
  evals.FALSE = function(tree, context) { return false; };

  evals.num = function(tree, context) {

    var n = tree[1].replace(/,/g, '');
    n = n.indexOf('.') > -1 ? parseFloat(n) : parseInt(n, 10);

    var a = tree.slice(2);
    if (a.includes('inv')) n = 1.0 / n;
    if (a.includes('opp')) n = -n;

    return n;
  };

  evals.arr = function(tree, context) {

    return tree.slice(1).map(function(c) { return self.eval(c, context); });
  };

  evals.plus = function(tree, context) {

    var elts = tree.slice(1).map(function(t) { return self.eval(t, context); });

    if (typeof elts[0] == 'number')
      return elts.reduce(function(r, e) { return r + e; }, 0);
    if (Array.isArray(elts[0]))
      return elts.reduce(function(r, e) { return r.concat(e); }, []);
    return null;
  };

  evals.MUL = function(tree, context) {

    return tree.slice(1)
      .reduce(function(r, t) { return r * self.eval(t, context); }, 1);
  };

  evals.SUM = function(tree, context) {

    var f = function(r, e) {
      if (typeof e == 'number') return r + e;
      if (Array.isArray(e)) return e.reduce(f, r);
      return r; };

    return(
      tree.slice(1).map(function(t) { return self.eval(t, context); })
        .reduce(f, 0));
  };

  evals.PRODUCT = function(tree, context) {

    var f = function(r, e) {
      if (typeof e == 'number') return r * e;
      if (Array.isArray(e)) return e.reduce(f, r);
      return r; };

    return(
      tree.slice(1).map(function(t) { return self.eval(t, context); })
        .reduce(f, 1));
  };

  evals.MIN = function(tree, context) {

    var es = tree.slice(1).map(function(t) { return self.eval(t, context); });

    if (es.find(function(e) { return (typeof e != 'number'); })) return es[0];
    return Math.min.apply(null, es);
  };

  evals.MAX = function(tree, context) {

    var es = tree.slice(1).map(function(t) { return self.eval(t, context); });

    if (es.find(function(e) { return (typeof e != 'number'); })) return es[0];
    return Math.max.apply(null, es);
  };

  evals.cmp = function(tree, context) {

    var cmp = tree[1];
    var a = self.eval(tree[2], context);
    var b = self.eval(tree[3], context);

    if (cmp === '=' || cmp === '!=') {

      var f = function(x) {
        if (x === null || x === undefined) return '';
        if (typeof x == 'string') return x;
        return JSON.stringify(x); };
      a = f(a);
      b = f(b);

      return (cmp === '=') ? a == b : a != b;
    }
    if (cmp === '>') return a > b;
    if (cmp === '<') return a < b;
    if (cmp === '>=') return a >= b;
    if (cmp === '<=') return a <= b;
    if (cmp === '=~') return !! a.match(b);
    if (cmp === 'IN') return b.includes(a);
    return false;
  };

  evals.IF = function(tree, context) {

    var c = self.eval(tree[1], context);

    if (c) return self.eval(tree[2], context);
    return self.eval(tree[3], context);
  };

  evals.CASE = function(tree, context) {

    var ctl = self.eval(tree[1], context);
    var args = tree.slice(2);

    if (typeof ctl == 'boolean') { args.unshift(ctl); ctl = true; }

    var def = args.length % 2 == 1 ? args.pop() : null;

    while (true) {
      var a = args.shift(); var b = args.shift();
      if (a === undefined && b === undefined) break;
      if (ctl === self.eval(a, context)) return self.eval(b, context);
    }

    return self.eval(def, context);
  };
  evals.SWITCH = evals.CASE;

  evals.AND = function(tree, context) {

    for (var i = 1, l = tree.length; i < l; i++) {
      if ( ! self.eval(tree[i], context)) return false;
    }
    return true;
  };

  evals.OR = function(tree, context) {

    for (var i = 1, l = tree.length; i < l; i++) {
      if (self.eval(tree[i], context)) return true;
    }
    return false;
  };

  evals.NOT = function(tree, context) { return ! self.eval(tree[1], context); };

  evals.MATCH = function(tree, context) {

    var elt = self.eval(tree[1], context);
    var arr = self.eval(tree[2], context);

    if ( ! Array.isArray(arr)) return -1;
    return arr.indexOf(elt);
  };

  evals.HAS = function(tree, context) {

    var col = self.eval(tree[1], context);
    var elt = self.eval(tree[2], context);

    if (Array.isArray(col)) return col.indexOf(elt) > -1;
    if (typeof col == 'object') return col.hasOwnProperty(elt);
      //var v = col[elt]; return v !== undefined && v !== null && v !== false;
    return false;
  };

  evals.INDEX = function(tree, context) {

    var col = self.eval(tree[1], context);
    var i = self.eval(tree[2], context);

    if ( ! Array.isArray(col)) return 0;
    if (typeof i != 'number') return 0;

    return (i < 0) ?
      col[col.length + i] :
      col[parseInt(i) - 1];
  };

  evals.COUNTA = function(tree, context) {

    var col = self.eval(tree[1], context);

    return Array.isArray(col) ? col.length : 0;
  };

  evals.UNIQUE = function(tree, context) {

    var arr = self.eval(tree[1], context);

    if ( ! Array.isArray(arr)) throw new Error(
      "UNIQUE() expects array not " + xtype(arr));

    //return arr.uniq(); // :-( why no load?
    return Array.from(new Set(arr));
  };

  // SORT({ 1, 3, 2 })         --> [ 1, 2, 3 ]
  // SORT({ 1, 3, 2 }, 1, -1)  --> [ 3, 2, 1 ]
  //
  evals.SORT = function(tree, context) {

    var arr = self.eval(tree[1], context);
    //var col = self.eval(tree[2], context);
    var dir = self.eval(tree[3], context);

    if ( ! Array.isArray(arr)) throw new Error(
      "UNIQUE() expects array not " + xtype(arr));

    return dir === -1 ? arr.sort().reverse() : arr.sort();
  };

  evals.ISBLANK = function(tree, context) {

    var val = self.eval(tree[1], context);

    return val === '' || val === undefined || val === null;
  };

  evals.ISNUMBER = function(tree, context) {

    return (typeof self.eval(tree[1], context) == 'number');
  };

  evals.PROPER = function(tree, context) {
    return(self.eval(tree[1], context))
      .replace(
        /(^|[^a-z])([a-z])/g,
        function(m, m1, m2) { return m1 + m2.toUpperCase(); });
  };
  evals.LOWER = function(tree, context) {
    return(self.eval(tree[1], context)).toLowerCase();
  };
  evals.UPPER = function(tree, context) {
    return(self.eval(tree[1], context)).toUpperCase();
  };

  evals.LN = function(tree, context) {
    var a = self.eval(tree[1], context);
    if (Array.isArray(a)) return a.map(Math.log);
    return Math.log(a);
  };
  evals.SQRT = function(tree, context) {
    var a = self.eval(tree[1], context);
    if (Array.isArray(a)) return a.map(Math.sqrt);
    return Math.sqrt(a);
  };

  var p2 = function(n) { return n * n; };

  evals.STDEV = function(tree, context) {

    var a = self.eval(tree[1], context);
    var s = a.reduce(function(acc, e) { return acc + e; }, 0);
    var m = s / a.length;
    s = a.reduce(function(acc, e) { return acc + p2(e - m); }, 0);
    var v = s / (a.length - 1);

    return Math.sqrt(v);
  };

  evals.VLOOKUP = function(tree, context) {

    var k = self.eval(tree[1], context);
    var t = self.eval(tree[2], context);
    var i = self.eval(tree[3], context);

    if (typeof i != 'number') throw new Error(
      `VLOOKUP() arg 3 '${tree[3]}' is not a number`);
    if ( ! Array.isArray(t)) throw new Error(
      `VLOOKUP() arg 2 '${tree[2]}' does not point to an array of array`);

    for (var j = 0, l = t.length; j < l; j++) {
      var r = t[j];
      if ( ! Array.isArray(r)) throw new Error(
        `VLOOKUP() arg 2 row ${j + 1} of table is not an array`);
      if (r[0] === k) return r[i - 1]; // found :-)
    }

    return null;
  };

  //
  // public functions

  this.peval = function(tree, context) {

    if (typeof tree == 'string') tree = Xel.parse(tree);

    var t0 = tree[0];
    var e = pevals[t0];

    if ( ! e && context._custom_functions) {
      context._eval = self.peval;
      e = context._custom_functions[t0];
    }
    if ( ! e) {
      throw new Error("no pevals." + tree[0] + " method");
    }

    return e(tree, context);
  };

  this.eval = function(tree, context) {

    if ( ! Array.isArray(tree) || (typeof tree[0] != 'string')) return tree;

    var t0 = tree[0];
    var e = evals[t0];

    if ( ! e && context._custom_functions) {
      context._eval = self.eval;
      e = context._custom_functions[t0];
    }
    if ( ! e) {
      throw new Error("no evals." + tree[0] + " method");
    }

    return e(tree, context);
  };

  this.parse = function(s) {

    return XelParser.parse(s)
  };

  this.seval = function(s, context) {

    s = s.trim(); if (s.match(/^=/)) s = s.slice(1).trim();

    return self.eval(self.parse(s), context);
  };

  this.s_eval = function(s, context) {

    return (typeof s == 'string') ? self.seval(s, context) : s;
  };

  this.neval = function(x, context) {

    if (typeof x != 'string') return x;

    var s = x.trim(); if (s.match(/^=/)) s = s.slice(1).trim();

    return self.eval(self.parse(s), context);
  };

  //this.keval = function(o, key, context, force) {
  //  var ukey = '_' + key;
  //  if (force) delete o[ukey];
  //  var t = o[ukey];
  //  if (t) return self.eval(t, context);
  //  var v = o[key];
  //  if ((typeof v == 'string') && v.trim()[0] === '=') {
  //    o[ukey] = self.parse(v.trim().slice(1).trim());
  //    return self.eval(o[ukey], context);
  //  }
  //  return v;
  //};

  //
  // done.

  return this;

}).apply({}); // end Xel

