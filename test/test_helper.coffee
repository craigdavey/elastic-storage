ElasticStorage = require ".."

# Use a cluster on non standard port for the tests.
ElasticStorage::port = 9201

exports.ElasticStorage = ElasticStorage

{assert} = require("nodeunit")

assert.assert = (result, message) ->
  assert.strictEqual result, true, message

assert.equality = (a, b, message) -> 
  assert.strictEqual(b, a, message)

assert.symmetry = (a, b, message) -> 
  assert.deepEqual(a, b, message)
