{ElasticStorage} = require "./test_helper"
{series} = require "async"

module.exports =
  setUp: (done) -> 
    (new ElasticStorage).drop "_all", done


  "initialize a new index in the cluster": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test", (error) ->
      console.error error if error
      test.equality error, undefined
      storage.drop "test", test.done


  "can’t initialize an index if it already exists": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test", (error) ->
      storage.init "test", (error) ->
        test.equality error.code, 400
        storage.drop "test", test.done


  "drop an existing index": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test", ->
      storage.drop "test", (error) ->
        test.equality error, undefined
        test.done()


  "can’t drop a non-existent index": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.drop "test", (error) ->
      test.equality error.code, 404
      test.done()


  "can’t drop all indices with blank address": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test", ->
      storage.drop "", (error) ->
        test.assert error.message.match("drop received a blank address")?
        storage.drop "test", test.done


  "dropping an alias drops associated indices": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test", ->
      storage.createAlias "test_alias", "test", ->
        storage.drop "test_alias", (error) ->
          storage.has "test", (error, exists) ->
            test.equality exists, no
            test.done()


  "storage.has(address) is true when index exists": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.init "test", ->
      storage.has "test", (error, exists) ->
        test.equality error, undefined
        test.equality exists, yes
        storage.drop "test", test.done


  "storage.has(address) is false when index is missing": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.has "test", (error, exists) ->
      test.equality error, undefined
      test.equality exists, no
      test.done()


  "refresh an existing index": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test", ->
      storage.refresh "test", (error) ->
        test.equality error, undefined
        storage.drop "test", test.done


  "can’t refresh an index that doesn’t exist": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.refresh "test", (error) ->
      test.equality error.code, 404
      test.done()


  "fetch indices when there are no indices": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.fetchIndices (error, indices) ->
      test.symmetry indices, []
      test.done()


  "fetch indices when there are some indices without aliases": (test) ->
    test.expect 1
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.init "test_001", ƒ
      (ƒ) -> storage.init "test_002", ƒ
    ], (error) ->
      storage.fetchIndices (error, indices) ->
        test.symmetry indices, [
          {id:"test_001", alias: undefined}
          {id:"test_002", alias: undefined}
        ]
        storage.drop "test_001,test_002", test.done


  "fetch indices when there is an index with one alias": (test) ->
    test.expect 1
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.init "test_001", ƒ
      (ƒ) -> storage.init "test_002", ƒ
      (ƒ) -> storage.createAlias "test", "test_001", ƒ
    ], (error) ->
      storage.fetchIndices (error, indices) ->
        test.symmetry indices, [
          {id:"test_001", alias: "test"}
          {id:"test_002", alias: undefined}
        ]
        storage.drop "test_001,test_002,test", test.done


  "fetch indices when there is an index with two alias": (test) ->
    test.expect 1
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.init "test_001", ƒ
      (ƒ) -> storage.init "test_002", ƒ
      (ƒ) -> storage.createAlias "test_alias_a", "test_001", ƒ
      (ƒ) -> storage.createAlias "test_alias_b", "test_001", ƒ
    ], (error) ->
      storage.fetchIndices (error, indices) ->
        test.symmetry indices, [
          {id:"test_001", alias: "test_alias_b"}
          {id:"test_002", alias: undefined}
        ]
        storage.drop "test_001,test_002", test.done
