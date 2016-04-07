{ElasticStorage} = require "./test_helper"

module.exports =
  setUp: (done) -> 
    (new ElasticStorage).drop "_all", done
        
  "create an alias for an existing index": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test_001", ->
      storage.createAlias "test", "test_001", (error, created) ->
        throw error if error?
        test.equality created, yes
        storage.drop "test_001", test.done

  "alias creation gracefully handles numeric index arguments": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test_001", ->
      storage.createAlias 1, "test_001", (error, created) ->
        throw error if error?
        test.equality created, yes
        storage.drop "test_001", test.done
  
  "can’t create an alias for an non-existent index": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.createAlias "test", "test_001", (error, created) ->
      test.equality error.code, 404
      test.equality created, no
      test.done()
  
  "can’t create an alias without source index name": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.createAlias "test", null, (error, created) ->
      test.equality error.code, 500
      test.equality created, no
      test.done()
  
  "can’t create an alias with undefined name": (test) ->
    test.throws -> storage.createAlias undefined
    test.done()
  
  "can’t create an alias with null name": (test) ->
    test.throws -> storage.createAlias null
    test.done()
  
  "remove an existing alias from an existing index": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test_001", ->
      storage.createAlias "test", "test_001", ->
        storage.deleteAlias "test", "test_001", (error, removed) ->
          throw error if error?
          test.equality removed, yes
          storage.drop "test_001", test.done
  
  "ok to remove non-existent alias from existing index": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test_001", ->
      storage.deleteAlias "test", "test_001", (error, removed) ->
        throw error if error?
        test.equality removed, yes
        storage.drop "test_001", test.done
  
  "can’t remove non-existent alias from non-existent index": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.deleteAlias "test", "test_001", (error, removed) ->
      test.equality error.code, 404
      test.equality removed, no
      test.done()
  
  "get a list of all the aliases": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.init "test_001", ->
      storage.createAlias "test", "test_001", ->
        storage.getAliases (error, aliases, map) ->
          throw error if error?
          test.symmetry aliases, ["test"]
          test.symmetry map, {"test": ["test_001"]}
          storage.drop "test_001", test.done
  
  "empty list when no aliases exist": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.getAliases (error, aliases, map) ->
      throw error if error?
      test.symmetry aliases, []
      test.symmetry map, {}
      test.done()
  
  "migrate an existing alias from one index to another": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.init "test_001", ->
      storage.createAlias "test", "test_001", ->
        storage.init "test_002", ->
          storage.migrate "test", "test_001", "test_002", (error, renamed) ->
            throw error if error?
            test.equality renamed, yes
            storage.drop "test_001,test_002", test.done
