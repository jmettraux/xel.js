
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
  function funname(i) { return rex('funname', i, /[_a-zA-Z][_a-zA-Z0-9]*/); }
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

  let root = cmp;

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

    let cn = t.children.slice(); // dup array
    let a = [ t.name === 'add' ? 'plus' : 'MUL' ];
    if (cn[1] && cn[1].strinp() === '&') a = [ 'amp' ]
    let mod = null;
    let c = null;

    while (c = cn.shift()) {
      let v = rewrite(c);
      if (mod) v = [ mod, v ];
      a.push(v);
      c = cn.shift();
      if ( ! c) break;
      mod = MODS[c.strinp()];
    }

    return a;
  }
  let rewrite_mul = rewrite_add;

  function rewrite_fun(t) {

    let a = [ t.children[0].strinp() ];
    t.children[1].children.forEach(function(c) {
      if (c.name) a.push(rewrite(c));
    });

    a._source = t.strinp();

    return a;
  }

  function rewrite_exp(t) { return rewrite(t.children[0]); }

  function rewrite_par(t) { return rewrite(t.children[1]); }

  function rewrite_arr(t) {
    let a = [ 'arr' ];
    for (let i = 0, l = t.children.length; i < l; i++) { let c = t.children[i];
      if (c.name) a.push(rewrite(c)); }
    return a; }

  function rewrite_var(t) { return [ 'var', t.strinp() ]; }
  function rewrite_number(t) { return [ 'num', t.strinp() ]; }

  function rewrite_string(t) {

    let s = t.children[0].strinp();
    let q = s[0];
    s = s.slice(1, -1);

    return [
      'str', q === '"' ? s.replace(/\\\"/g, '"') : s.replace(/\\'/g, "'") ];
  }
}); // end XelParser


var Xel = (function() {

  "use strict";

  this.VERSION = '1.5.1';

  let self = this;

  //
  // protected functions

  let xtype = function(x) {

    return(
      x === null ? 'null' :
      Array.isArray(x) ? 'array' :
      (typeof x));
  };

  let evalArgs = function(tree, context) {
    //return tree.slice(1).map(function(t) { return self.eval(t, context); });};

    let a = [];
    let max = arguments[2];

    for (let i = 1, l = tree.length; i < l; i++) {

      let t = tree[i];

      if ( ! t) break;
      if (max && a.length === max) break;

      a.push(self.eval(t, context));
    }

    return a;
  };

  let evals = {};

  evals.var = function(tree, context) {

    let v = context;

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

    let n = tree[1].replace(/,/g, '');
    n = n.indexOf('.') > -1 ? parseFloat(n) : parseInt(n, 10);

    let a = tree.slice(2);
    if (a.includes('inv')) n = 1.0 / n;
    if (a.includes('opp')) n = -n;

    return n;
  };

  evals.arr = function(tree, context) {

    return tree.slice(1).map(function(c) { return self.eval(c, context); });
  };

  evals.plus = function(tree, context) {

    let elts = tree.slice(1).map(function(t) { return self.eval(t, context); });

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
          let v = self.eval(t, context);
          return (v === undefined || v === null) ? '' : '' + v; })
        .join(''));
  };

  evals.MUL = function(tree, context) {

    return tree.slice(1)
      .reduce(function(r, t) { return r * self.eval(t, context); }, 1);
  };

  evals.SUM = function(tree, context) {

    let f = function(r, e) {
      if (typeof e == 'number') return r + e;
      if (Array.isArray(e)) return e.reduce(f, r);
      return r; };

    return(
      tree.slice(1).map(function(t) { return self.eval(t, context); })
        .reduce(f, 0));
  };

  evals.PRODUCT = function(tree, context) {

    let f = function(r, e) {
      if (typeof e == 'number') return r * e;
      if (Array.isArray(e)) return e.reduce(f, r);
      return r; };

    return(
      tree.slice(1).map(function(t) { return self.eval(t, context); })
        .reduce(f, 1));
  };

  evals.MIN = function(tree, context) {

    let es = tree.slice(1).map(function(t) { return self.eval(t, context); });

    if (es.find(function(e) { return (typeof e != 'number'); })) return es[0];
    return Math.min.apply(null, es);
  };

  evals.MAX = function(tree, context) {

    let es = tree.slice(1).map(function(t) { return self.eval(t, context); });

    if (es.find(function(e) { return (typeof e != 'number'); })) return es[0];
    return Math.max.apply(null, es);
  };

  evals.cmp = function(tree, context) {

    let cmp = tree[1];
    let a = self.eval(tree[2], context);
    let b = self.eval(tree[3], context);

    if (cmp === '=' || cmp === '!=') {

      let f = function(x) {
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

    let c = self.eval(tree[1], context);

    if (c) return self.eval(tree[2], context);
    return self.eval(tree[3], context);
  };

  evals.CASE = function(tree, context) {

    let ctl = self.eval(tree[1], context);
    let args = tree.slice(2);

    if (typeof ctl == 'boolean') { args.unshift(ctl); ctl = true; }

    let def = args.length % 2 == 1 ? args.pop() : null;

    while (true) {
      let a = args.shift(); let b = args.shift();
      if (a === undefined && b === undefined) break;
      if (ctl === self.eval(a, context)) return self.eval(b, context);
    }

    return self.eval(def, context);
  };
  evals.SWITCH = evals.CASE;

  evals.AND = function(tree, context) {

    for (let i = 1, l = tree.length; i < l; i++) {
      if ( ! self.eval(tree[i], context)) return false;
    }
    return true;
  };

  evals.OR = function(tree, context) {

    for (let i = 1, l = tree.length; i < l; i++) {
      if (self.eval(tree[i], context)) return true;
    }
    return false;
  };

  evals.NOT = function(tree, context) { return ! self.eval(tree[1], context); };

  evals.ORV = function(tree, context) {

    for (let i = 1, l = tree.length; i < l; i++) {
      let v = self.eval(tree[i], context);
      if (v !== '' && v !== undefined && v !== null) return v;
    }
    return undefined;
  };

  evals.MATCH = function(tree, context) {

    let [ elt, arr ] = evalArgs(tree, context, 2);

    if ( ! Array.isArray(arr)) return -1;
    return arr.indexOf(elt);
  };

  evals.HAS = function(tree, context) {

    let [ col, elt ] = evalArgs(tree, context, 2);

    if (Array.isArray(col)) return col.indexOf(elt) > -1;
    if (typeof col == 'object') return col.hasOwnProperty(elt);
      //var v = col[elt]; return v !== undefined && v !== null && v !== false;
    return false;
  };

  evals.INDEX = function(tree, context) {

    let col = self.eval(tree[1], context);
    let i = self.eval(tree[2], context);

    if ( ! Array.isArray(col)) return 0;
    if (typeof i != 'number') return 0;

    return (i < 0) ?
      col[col.length + i] :
      col[parseInt(i) - 1];
  };

  evals.COUNTA = function(tree, context) {

    let col = self.eval(tree[1], context);

    return Array.isArray(col) ? col.length : 0;
  };

  evals.UNIQUE = function(tree, context) {

    let arr = self.eval(tree[1], context);

    if ( ! Array.isArray(arr)) throw new Error(
      "UNIQUE() expects array not " + xtype(arr));

    //return arr.uniq(); // :-( why no load?
    return Array.from(new Set(arr));
  };

  // SORT({ 1, 3, 2 })         --> [ 1, 2, 3 ]
  // SORT({ 1, 3, 2 }, 1, -1)  --> [ 3, 2, 1 ]
  //
  evals.SORT = function(tree, context) {

    let arr = self.eval(tree[1], context);
    //var col = self.eval(tree[2], context);
    let dir = self.eval(tree[3], context);

    if ( ! Array.isArray(arr)) throw new Error(
      "UNIQUE() expects array not " + xtype(arr));

    return dir === -1 ? arr.sort().reverse() : arr.sort();
  };

  evals.ISBLANK = function(tree, context) {

    let val = self.eval(tree[1], context);

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
    let a = self.eval(tree[1], context);
    if (Array.isArray(a)) return a.map(Math.log);
    return Math.log(a);
  };
  evals.SQRT = function(tree, context) {
    let a = self.eval(tree[1], context);
    if (Array.isArray(a)) return a.map(Math.sqrt);
    return Math.sqrt(a);
  };

  let p2 = function(n) { return n * n; };

  evals.STDEV = function(tree, context) {

    let a = self.eval(tree[1], context);
    let s = a.reduce(function(acc, e) { return acc + e; }, 0);
    let m = s / a.length;
    s = a.reduce(function(acc, e) { return acc + p2(e - m); }, 0);
    let v = s / (a.length - 1);

    return Math.sqrt(v);
  };

  evals.VLOOKUP = function(tree, context) {

    let [ k, t, i ] = evalArgs(tree, context, 3);

    if (typeof i != 'number') throw new Error(
      `VLOOKUP() arg 3 '${tree[3]}' is not a number`);
    if ( ! Array.isArray(t)) throw new Error(
      `VLOOKUP() arg 2 '${tree[2]}' does not point to an array of array`);

    for (let j = 0, l = t.length; j < l; j++) {
      let r = t[j];
      if ( ! Array.isArray(r)) throw new Error(
        `VLOOKUP() arg 2 row ${j + 1} of table is not an array`);
      if (r[0] === k) return r[i - 1]; // found :-)
    }

    return null;
  };

  evals.LAMBDA = function(tree, context) {

    let args = tree.slice(1).map(function(t) { return t[1]; });

    let code = tree[tree.length - 1];

    let l = function() {

      let as = Array.from(arguments);

      let ctx1 = Object.assign({}, context, as.pop());
      for (let i = 0, l = args.length; i < l; i++) { ctx1[args[i]] = as[i]; }

      return self.eval(code, ctx1);
    };

    l._source = tree._source;

    return l;
  };

  evals.KALL = function(tree, context) {

    let as = evalArgs(tree, context);
    as.push(context);

    let fun = as.shift();

    return fun.apply(null, as);
  };

  evals.MAP = function(tree, context) {

    let [ arr, fun ] = evalArgs(tree, context, 2);

    return arr.map(function(e) { return fun.apply(null, [ e, context ]); });
  };

  evals.REDUCE = function(tree, context) {

    let t = tree.slice(1);

    let fun = self.eval(t.pop(), context);

    let acc, arr;
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

    let agg = function(acc, x) {
      if (typeof x === 'string') { acc.push(x.trim()); }
      else if (Array.isArray(x)) { x.forEach(function(xx) { agg(acc, xx); }); }
      else if (x === null || x === undefined) { acc.push(''); }
      else { acc.push(JSON.stringify(x)); }
      return acc; };

    let [ del, ign ] = evalArgs(tree, context, 2);

    let txs = [];
    tree.slice(3).forEach(function(tt) { agg(txs, self.eval(tt, context)); });

    if (ign) txs = txs.filter(function(t) { return t.length > 0; });

    return txs.join(del);
  };

  evals.LET = function(tree, context) {

    let ctx = Object.assign({}, context);
    let tl = tree.length;

    let key = null;
    for (let i = 1, l = tl - 1; i < l; i++) {
      let t = tree[i];
      if (i % 2 === 1) { key = t[0] === 'var' ? t[1] : '' + self.eval(t, ctx); }
      else { ctx[key] = self.eval(t, ctx); }
    }

    return self.eval(tree[tl - 1], ctx);
  };

  evals.MROUND = function(tree, context) {

    let [ n, m ] = evalArgs(tree, context, 2);

    if (n * m < 0) return NaN;
    return Math.round(n / m) * m;
  };

  evals.MROUND2 = function(tree, context) {

    let [ n, m ] = evalArgs(tree, context, 2);

    if (n * m < 0) return NaN;

    let r = Math.round(n / m) * m * 100;

    return (r - r % 1) / 100;
  };

  evals.CEILING = function(tree, context) {

    let as = evalArgs(tree, context);
    if (as.length < 2) as.push(1);
    let n = as[0], m = as[1];

    let r = (n % m);
    return r === 0 ? n : n - r + m;
  };

  evals.FLOOR = function(tree, context) {

    let as = evalArgs(tree, context);
    if (as.length < 2) as.push(1);
    let n = as[0], m = as[1];

    return n - (n % m);
  };

  evals.ROUND = function(tree, context) {

    let as = evalArgs(tree, context);
    if (as.length < 2) as.push(0);
    let n = as[0], m = as[1];

    let t = 10 ** m;
    return Math.round(n * t) / t;
  };

  evals.TRUNC = function(tree, context) {

    let as = evalArgs(tree, context);
    if (as.length < 2) as.push(0);

    let n = as[0], m = 10 ** as[1];

    return Math.floor(n * m) / m;
  };

  const treeCache = {};

  //
  // public functions

  this.callbacks = [];

  this.eval = function(tree, context) {

    let cbs = self.callbacks.concat(context._callbacks || []);
    cbs.forEach(function(f) { f(tree, context); });

    if ( ! Array.isArray(tree) || (typeof tree[0] != 'string')) return tree;

    let t0 = tree[0];
    let e = evals[t0];
    let v = context[t0];

    let ret = undefined;

    if ( ! e && context._custom_functions) {
      context._eval = self.eval;
      e = context._custom_functions[t0];
    }

    if ( ! e && (typeof v === 'function')) {
      let args = tree.slice(1)
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

    cbs.forEach(function(f) { f(tree, context, ret); });

    return ret;
  };

  this.listCachedTrees = function() { return treeCache; };

  this.parse = function(s) {

    let h = self.sash(s);
    let t = treeCache[h]; if ( ! t) t = treeCache[h] = XelParser.parse(s);

    return t;
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

    let s = x.trim(); if (s.match(/^=/)) s = s.slice(1).trim();

    return self.eval(self.parse(s), context);
  };

  //this.keval = function(o, key, context, force) {
  //  let ukey = '_' + key;
  //  if (force) delete o[ukey];
  //  let t = o[ukey];
  //  if (t) return self.eval(t, context);
  //  let v = o[key];
  //  if ((typeof v == 'string') && v.trim()[0] === '=') {
  //    o[ukey] = self.parse(v.trim().slice(1).trim());
  //    return self.eval(o[ukey], context);
  //  }
  //  return v;
  //};

  this.sash = function(s) {

    let l = s.length;
    let h = 0;

    for (let i = 0; i < l; i++) h = s.charCodeAt(i) + (h << 6) + (h << 16) - h;

    return `${s.slice(0, 7)}|${s.charAt(l / 2)}|${s.slice(l - 7, l)}|${l}|${h}`;
  };

  //
  // done.

  return this;

}).apply({}); // end Xel

