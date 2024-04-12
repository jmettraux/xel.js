
// xel.js

var XelParser = Jaabro.makeParser(function() {

  // parse

  function aa(i) { return rex(null, i, /\{\s*/); }
  function az(i) { return rex(null, i, /\}\s*/); }
  function pa(i) { return rex(null, i, /\(\s*/); }
  function pz(i) { return rex(null, i, /\)\s*/); }
  function com(i) { return rex(null, i, /,\s*/); }

  function number(i) {
    return rex('number', i,
      /-?(\.[0-9]+|([0-9][,0-9]*[0-9]|[0-9]+)(\.[0-9]+)?)\s*/); }

  function vra(i) { return rex('var', i, /[a-z_][A-Za-z0-9_.]*\s*/); }

  function arr(i) { return eseq('arr', i, aa, cmp, com, az); }

  function qstring(i) { return rex('qstring', i, /'(\\'|[^'])*'\s*/); }
  function dqstring(i) { return rex('dqstring', i, /"(\\"|[^"])*"\s*/); }
  function string(i) { return alt('string', i, dqstring, qstring); }

  function funargs(i) { return eseq('funargs', i, pa, cmp, com, pz); }
  function funname(i) { return rex('funname', i, /[a-zA-Z][_a-zA-Z0-9]*/); }
  function fun(i) { return seq('fun', i, funname, funargs); }

  function comparator(i) {
    return rex('comparator', i, /([\<\>]=?|=~|!?=|IN)\s*/); }
  function multiplier(i) {
    return rex('multiplier', i, /[*\/]\s*/); }
  function adder(i) {
    return rex('adder', i, /[-+&]\s*/); }

  function par(i) { return seq('par', i, pa, cmp, pz); }
  function exp(i) { return alt('exp', i, par, fun, number, string, arr, vra); }

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
      t.children[1].children[0].strinp(),
      rewrite(t.children[0]),
      rewrite(t.children[1].children[1])
    ];
  }

  const MODS = { '-': 'opp', '/': 'inv' };

  function rewrite_add(t) {

    if (t.children.length === 1) return rewrite(t.children[0]);

    var cn = t.children.slice(); // dup array
    var a = [ t.name === 'add' ? 'plus' : 'MUL' ];
    if (cn[1] && cn[1].strinp() === '&') a = [ 'amp' ]
    var mod = null;
    var c = null;

    while (c = cn.shift()) {
      var v = rewrite(c);
      if (mod) v = [ mod, v ];
      a.push(v);
      c = cn.shift();
      if ( ! c) break;
      mod = MODS[c.strinp()];
    }

    return a;
  }
  var rewrite_mul = rewrite_add;

  function rewrite_fun(t) {

    var a = [ t.children[0].strinp() ];
    t.children[1].children.forEach(function(c) {
      if (c.name) a.push(rewrite(c));
    });

    a._source = t.strinp();

    return a;
  }

  function rewrite_exp(t) { return rewrite(t.children[0]); }

  function rewrite_par(t) { return rewrite(t.children[1]); }

  function rewrite_arr(t) {
    var a = [ 'arr' ];
    t.children.forEach(function(c) { if (c.name) a.push(rewrite(c)); });
    return a; }

  function rewrite_var(t) { return [ 'var', t.strinp() ]; }
  function rewrite_number(t) { return [ 'num', t.strinp() ]; }

  function rewrite_string(t) {

    var s = t.children[0].strinp();
    var q = s[0];
    var s = s.slice(1, -1);

    return [
      'str', q === '"' ? s.replace(/\\\"/g, '"') : s.replace(/\\'/g, "'") ];
  }
}); // end XelParser


var Xel = (function() {

  "use strict";

  this.VERSION = '1.4.0';

  var self = this;

  //
  // protected functions

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

  evals.amp = function(tree, context) {

    return(
      tree.slice(1)
        .map(function(t) {
          var v = self.eval(t, context);
          return (v === undefined || v === null) ? '' : '' + v; })
        .join(''));
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

  evals.ORV = function(tree, context) {

    for (var i = 1, l = tree.length; i < l; i++) {
      var v = self.eval(tree[i], context);
      if (v !== '' && v !== undefined && v !== null) return v;
    }
    return undefined;
  };

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

  evals.LAMBDA = function(tree, context) {

    var args = []; for (var i = 1, l = tree.length - 1; i < l; i++) {
      args.push(tree[i][1]); }

    var code = tree[tree.length - 1];

    var l = function() {

      var as = Array.from(arguments);

      var ctx1 = Object.assign({}, context, as.pop());
      for (var i = 0, l = args.length; i < l; i++) { ctx1[args[i]] = as[i]; }

      return self.eval(code, ctx1);
    };

    l._source = tree._source;

    return l;
  };

  evals.KALL = function(tree, context) {

    var args = []; for (var i = 1, l = tree.length; i < l; i++) {
      args.push(self.eval(tree[i], context)); }
    args.push(context);

    var fun = args.shift();

    return fun.apply(null, args);
  };

  evals.MAP = function(tree, context) {

    var arr = self.eval(tree[1], context);
    var fun = self.eval(tree[2], context);

    return arr.map(function(e) { return fun.apply(null, [ e, context ]); });
  };

  evals.REDUCE = function(tree, context) {

    var t = tree.slice(1);

    var fun = self.eval(t.pop(), context);

    var acc, arr;
      if (t.length === 1) {
        arr = self.eval(t[0], context);
        acc = arr.shift();
      }
      else {
        acc = self.eval(t[0], context);
        arr = self.eval(t[1], context);
      }

    return arr.reduce(fun, acc);
  };

  evals.TEXTJOIN = function(tree, context) {

    var agg = function(acc, x) {
      if (typeof x === 'string') { acc.push(x.trim()); }
      else if (Array.isArray(x)) { x.forEach(function(xx) { agg(acc, xx); }); }
      else if (x === null || x === undefined) { acc.push(''); }
      else { acc.push(JSON.stringify(x)); }
      return acc; };

    var del = self.eval(tree[1], context);
    var ign = self.eval(tree[2], context);

    var txs = [];
    tree.slice(3).forEach(function(tt) { agg(txs, self.eval(tt, context)); });

    if (ign) txs = txs.filter(function(t) { return t.length > 0; });

    return txs.join(del);
  };

  evals.LET = function(tree, context) {

    var ctx = Object.assign({}, context);
    var tl = tree.length;

    var key = null;
    for (var i = 1, l = tl - 1; i < l; i++) {
      var t = tree[i];
      if (i % 2 === 1) { key = t[0] === 'var' ? t[1] : '' + self.eval(t, ctx); }
      else { ctx[key] = self.eval(t, ctx); }
    }

    return self.eval(tree[tl - 1], ctx);
  };

  evals.MROUND = function(tree, context) {

    var n = self.eval(tree[1], context);
    var m = self.eval(tree[2], context);

    if (n * m < 0) return NaN;
    return Math.round(n / m) * m;
  };

  evals.MROUND2 = function(tree, context) {

    var n = self.eval(tree[1], context);
    var m = self.eval(tree[2], context);

    if (n * m < 0) return NaN;

    var r = Math.round(n / m) * m;
    r = r * 100;

    return (r - r % 1) / 100;
  };

  //
  // public functions

  this.callbacks = [];

  this.eval = function(tree, context) {

    self.callbacks.forEach(function(f) { f(tree, context); });

    if ( ! Array.isArray(tree) || (typeof tree[0] != 'string')) return tree;

    var t0 = tree[0];
    var e = evals[t0];
    var v = context[t0];

    var ret = undefined;

    if ( ! e && context._custom_functions) {
      context._eval = self.eval;
      e = context._custom_functions[t0];
    }

    if ( ! e && (typeof v === 'function')) {
      var args = tree.slice(1)
        .map(function(t) { return self.eval(t, context); });
      args.push(context);
      ret = v.apply(null, args);
    }
    else if ( ! e) {
      throw new Error("no evals." + tree[0] + " method");
    }
    else {
      ret = e(tree, context);
    }

    self.callbacks.forEach(function(f) { f(tree, context, ret); });

    return ret;
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

