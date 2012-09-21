{ElasticStorage} = require "./test_helper"
{series} = require "async"
Backbone = require "backbone"

module.exports =
  tearDown: (done) -> (new ElasticStorage).drop "test", done


  "create from a model with a `storageAddress` method": (test) ->
    test.expect 1
    model = new Backbone.Model
    model.sync = ElasticStorage.setupBackboneSync()
    model.storageAddress = -> 
      if @isNew() then "test/models" else "test/models/#{@id}"

    model.save null,
      success: ->
        test.assert model.has("id")
        test.done()


  "create from a model with a `url` method": (test) ->
    test.expect 1
    model = new Backbone.Model
    model.sync = ElasticStorage.setupBackboneSync()
    model.url = -> 
      if @isNew() then "test/models" else "test/models/#{@id}"

    model.save null,
      success: ->
        test.assert model.has("id")
        test.done()


  "fetch a model": (test) ->
    test.expect 1
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.index "test/models/1", {"name": "Duke"}, ƒ
      (ƒ) -> storage.refresh "test", ƒ
    ], ->
      model = new Backbone.Model
      model.sync = ElasticStorage.setupBackboneSync(storage)
      model.url = "test/models/1"
      model.fetch
        success: ->
          test.symmetry model.toJSON(),
            "id": "1"
            "name": "Duke"
          test.done()


  "fetch a collection": (test) ->
    test.expect 1
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.index "test/models/1", {"name": "Duke"}, ƒ
      (ƒ) -> storage.index "test/models/2", {"name": "Luke"}, ƒ
      (ƒ) -> storage.refresh "test", ƒ
    ], ->
      collection = new Backbone.Collection
      collection.sync = ElasticStorage.setupBackboneSync(storage)
      collection.url = "test/models"
      collection.fetch
        success: ->
          test.symmetry collection.toJSON(), [
            {"id": "1", "name": "Duke"}
            {"id": "2", "name": "Luke"}
          ]
          test.done()


  "fetch a collection with criteria": (test) ->
    test.expect 1
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.index "test/models/1", {"name": "Duke"}, ƒ
      (ƒ) -> storage.index "test/models/2", {"name": "Luke"}, ƒ
      (ƒ) -> storage.refresh "test", ƒ
    ], ->
      collection = new Backbone.Collection
      collection.sync = ElasticStorage.setupBackboneSync(storage)
      collection.url = "test/models"
      collection.criteria = {"size": 1}
      collection.fetch
        success: ->
          test.symmetry collection.toJSON(), [
            {"id": "1", "name": "Duke"}
          ]
          test.done()


  "update a model": (test) ->
    test.expect 1
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.index "test/models/1", {"name": "Duke"}, ƒ
      (ƒ) -> storage.refresh "test", ƒ
    ], ->
      model = new Backbone.Model
      model.sync = ElasticStorage.setupBackboneSync()
      model.url = "test/models/1"
      model.fetch
        success: ->
          model.set "name", "Duke Lukas"
          model.save null,
            success: ->
              test.equality model.get("name"), "Duke Lukas"
              test.done()


  "delete a model": (test) ->
    test.expect 1
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.index "test/models/1", {"name": "Duke"}, ƒ
      (ƒ) -> storage.refresh "test", ƒ
    ], ->
      model = new Backbone.Model
      model.sync = ElasticStorage.setupBackboneSync()
      model.url = "test/models/1"
      model.fetch
        success: ->
          model.destroy
            success: ->
              storage.has "test/models/1", (error, exists) ->
                test.equality exists, no
                test.done()
