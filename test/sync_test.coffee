{ElasticStorage} = require "./test_helper"
{series, nextTick} = require "async"
Backbone = require "backbone"

module.exports =
  setUp:    (done) -> (new ElasticStorage).init "test", done
  tearDown: (done) -> (new ElasticStorage).drop "test", done

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
          console.info model.toJSON()
          test.symmetry model.toJSON(),
            "id": "1"
            "name": "Duke"
          test.done()


  "fetch a collection of models without criteria": (test) ->
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
          test.same collection.toJSON(), [
            {"id": "2", "name": "Luke"}
            {"id": "1", "name": "Duke"}
          ]
          test.done()


  "fetch a collection of models with criteria": (test) ->
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
      collection.criteria =
        "sort": "name"
        "size": 1
      collection.fetch
        success: ->
          test.same collection.toJSON(), [
            {"id": "1", "name": "Duke"}
          ]
          test.done()


  "save model and listen for sync event": (test) ->
    test.expect 1

    model = new Backbone.Model
    model.sync = ElasticStorage.setupBackboneSync()
    model.storageAddress = ->
      if @isNew() then "test/models" else "test/models/#{@id}"

    model.save()

    model.on "sync", ->
      test.assert model.has("id")
      test.done()


  "save model and listen for error event": (test) ->
    test.expect 1

    storage = new ElasticStorage
    storage.create = (address, attributes, callback) ->
      nextTick -> callback("Error occurred")

    model = new Backbone.Model
    model.sync = ElasticStorage.setupBackboneSync(storage)
    model.storageAddress = ->
      if @isNew() then "test/models" else "test/models/#{@id}"

    model.save()

    model.on "error", ->
      test.assert true
      test.done()


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
