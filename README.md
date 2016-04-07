# Elastic Storage

Elastic Storage is a miniature [elasticsearch](http://elasticsearch.org) library for [Node](http://nodejs.org).
It gives you a simplified elasticsearch API and an easy synchronization layer for [Backbone](http://backbonejs.org) models.

The [source code](https://github.com/craigdavey/elastic_storage) and examples are written in [CoffeeScript](http://backbonejs.org), however,
you don’t need to install CoffeeScript to use Elastic Storage.
This module provides Javascript code that will work in any modern Node program.

Elastic Storage has two external dependencies: [Async](https://github.com/caolan/async) and [Underscore](http://underscorejs.org). These will be installed automatically by `npm`.

### Get Started

Run `npm install elastic_storage` to get the module and then require the constructor in your program:

    ElasticStorage = require "elastic_storage"

Now you can construct an `ElasticStorage` instance to work with:

    storage = new ElasticStorage
      host: "localhost"
      port: 9200

Your `storage` instance provides `index`, `search`, `create`, `read`, `update`, `delete`, `init`, `drop` and `refresh` methods. All of these methods accept an `address` argument that refers to an elasticsearch URL. And they all accept a Node style `callback` function. [Review the annotated source code for details](http://craig.memos.dev:3000/docs/node_modules/elastic_storage/src/index.coffee).

### Synchronize with Backbone

If you want to store your Backbone models in elasticsearch use `ElasticStorage.setupBackboneSync()` to replace `Backbone.sync`. The setup method accepts the same `options` as the `ElasticStorage` constructor:

    Backbone.sync = ElasticStorage.setupBackboneSync
      host: "storage.example.com"
      port: 9200

If your model (or collection) defines a `storageAddress` it will be used
as the `address` argument for storage methods. If there is no `storageAddress`
the object’s `url` will be used instead. You should probably define both
methods if your models are used in multiple environments. Use `model.url()`
on the client side and `model.storageAddress()` on the server:

    class Memo extends Backbone.Model
      storageAddress: ->
        "app/#{@url()}"

      url: ->
        if @isNew()
          "memos"
        else
          "memos/#{@id}"

Define `criteria` on any collections that should be reduced or sorted. 
Specify your `criteria` with the [query DSL](http://www.elasticsearch.org/guide/reference/query-dsl/).

    class ArchivedMemos extends Backbone.Collection
      storageAddress: ->
        "app/memos"

      criteria: ->
        filter: {exists: {field: "archived_at"}}
        sort: {"updated_at": {order:"desc"}}
        size: 100


### Adding records to elasticsearch

Add a memo to the `"business"` index:

    memo =
      "body": "Here is the new vacation policy..."
      "archived_at": "2012-06-01T12:00:00"
      "updated_at": new Date

    storage.index "business/memos", memo, (error) ->
      if error is undefined
        console.info "The memo was added."
      else
        console.error error


### Searching for records

Search for archived memos that match `"vacation policy"`:

    criteria =
      query:
        match:
          "memos.body": "vacation policy"
      highlight:
        fields:
          "memos.body":
            "number_of_fragments": 3
            "fragment_size": 150
      filter:
        exists:
          field: "archived_at"
      sort:
        "updated_at"
      size:
        100

    storage.search "business/memos", criteria, (error, hits) ->
      if hits
        console.info "#{hits.length} hits were received."
        console.info "#{hits.total} hits are available."
        for hit in hits
          console.info "Search hit score:"
          console.info hit.score
          console.info "Search hit attributes:"
          console.info hit.record
          console.info "Search hit highlights:"
          console.info hit.highlights
      else
        console.error error


### Working with Indices

Initialize a new index named `"garage"`:

    storage.init "garage", (error) ->
      if error is undefined
        console.info "Index named 'garage' was successfully initialized."
      else
        console.error error


Destroy all the indices in your cluster:

    storage.drop "_all", (error) ->
      if error is undefined
        console.info "All of your records were erased."
      else
        console.error error


Index a few records and then refresh the `"mail"` index to make them available to search:

    async.series [
      (ƒ) -> storage.index "mail/inbox", {subject: "Dinner plans"}, ƒ
      (ƒ) -> storage.index "mail/inbox", {subject: "Re: Dinner plans"}, ƒ
      (ƒ) -> storage.index "mail/inbox", {subject: "Re: Dinner plans"}, ƒ
      (f) -> storage.refresh "mail", ƒ
    ], (error) ->
      if error is undefined
        console.info "New mail records are now available for search."
      else
        console.error error


### Running Tests

Start a cluster at `http://localhost:9201/` and then run `npm test`.
