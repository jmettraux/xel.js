
# xel.js

Interpreting expressions built out of a subset of spreadsheet functions.

```js
// Xel.seval(code, context)
//   where context is a mapping var_name -> var_value

Xel.seval("	= CASE(a<5000000, 0.6, a<10000000, 0.55, 0.45)", { a: 10000 })
// --> 0.6

Xel.seval("CASE(a<5000000, 0.6, a<10000000, 0.55, 0.45)", { a: 5_100_000 })
// --> 0.55
```

See core spec at [spec/_xel.rb](spec/_xel.rb).

## License

MIT, see [LICENSE.txt](LICENSE.txt)

