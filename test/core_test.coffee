{ElasticStorage} = require "./test_helper"
{series} = require "async"

module.exports =
  setUp: (done) ->
    @storage = new ElasticStorage
    series [
      (ƒ) => @storage.index "test/memos/1", {text:"Hello World. Goodbye Moon."}, ƒ
      (ƒ) => @storage.index "test/memos/2", {text:"Ola"}, ƒ
      (ƒ) => @storage.index "test/memos/3", {text:"Salut"}, ƒ
      (ƒ) => @storage.refresh "test", ƒ
    ], done
    
  tearDown: (done) ->
    @storage.drop "test", done


  "searching with blank criteria returns all records": (test) ->
    criteria = {}
    @storage.search "test/memos", criteria, (error, hits) ->
      test.equality hits.length, 3
      test.done(error)


  "searching criteria returns matching records": (test) ->
    criteria =
      "query":
        "text":
          "_all": "Hello"
    @storage.search "test/memos", criteria, (error, hits) ->
      test.equality hits.length, 1
      test.equality hits[0].record["id"], "1"
      test.equality typeof hits[0].score, "number"
      test.done(error)


  "search b": (test) ->
    criteria =
      "query":
        "text": 
          "text": "Hello Moon."
    @storage.search "test/memos", criteria, (error, hits) ->
      test.equality hits.length, 1
      test.done(error)


  "search returns empty array when no records match": (test) ->
    criteria =
      "query":
        "text":
          "_all": "Not Applicable"
    @storage.search "test/memos", criteria, (error, hits) ->
      test.equality hits.length, 0
      test.done(error)
