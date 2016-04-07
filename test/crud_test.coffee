{ElasticStorage} = require "./test_helper"
{series} = require "async"

module.exports =
  tearDown: (done) -> 
    (new ElasticStorage).drop "_all", done


  "record is assigned an id attribute when it is created": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.create "test/records", {}, (error, record) ->
      test.assert record["id"]?
      test.done(error)


  "created and updated timestamps are assigned when a record is created": (test) ->
    test.expect 3
    storage = new ElasticStorage
    storage.create "test/records", {}, (error, record) ->
      test.assert record["created_at"]?
      test.assert record["updated_at"]?
      test.equality record["created_at"], record["updated_at"]
      test.done(error)


  "read a record from storage (with 3 arguments)": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.update "test/records/1", "title":"Untitled", ->
      storage.read "test/records/1", null, (error, record) ->
        test.equality record["id"], "1"
        test.equality record["title"], "Untitled"
        test.done(error)


  "read a record from storage (with 2 arguments)": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.update "test/records/1", "title":"Untitled", ->
      storage.read "test/records/1", (error, record) ->
        test.equality record["id"], "1"
        test.equality record["title"], "Untitled"
        test.done(error)


  "can’t read a record that doesn’t exist": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.read "test/records/1", null, (error, record) ->
      test.equality error.code, 404
      test.equality record, undefined
      test.done()


  "read collection of records from storage (with 3 arguments)": (test) ->
    test.expect 3
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.index "test/records/1", {"name": true}, ƒ
      (ƒ) -> storage.index "test/records/2", {"name": true}, ƒ
      (ƒ) -> storage.refresh "test", ƒ
    ], (error) ->
      storage.read "test/records", {}, (error, records) ->
        test.equality records.length, 2
        test.assert records[0]["name"]
        test.assert records[1]["name"]
        test.done(error)


  "read collection of records from storage (with 2 arguments)": (test) ->
    test.expect 3
    storage = new ElasticStorage
    series [
      (ƒ) -> storage.index "test/records/1", {"name": true}, ƒ
      (ƒ) -> storage.index "test/records/2", {"name": true}, ƒ
      (ƒ) -> storage.refresh "test", ƒ
    ], (error) ->
      storage.read "test/records", (error, records) ->
        test.equality records.length, 2
        test.assert records[0]["name"]
        test.assert records[1]["name"]
        test.done(error)


  "update record attributes": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.update "test/records/1", "title":"A day in the park", (error, record) =>
      test.equality record["id"], "1"
      test.equality record["title"], "A day in the park"
      test.done(error)


  "update record with `now` keyword in time attribute": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.update "test/records/1", {"stopped_at": "now"}, (error, record) =>
      test.assert /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$/.test(record["stopped_at"])
      test.done(error)


  "delete a record": (test) ->
    test.expect 2
    storage = new ElasticStorage
    storage.index "test/records/1", {}, ->
      storage.delete "test/records/1", (error) ->
        test.equality error, undefined
        storage.read "test/records/1", null, (error) ->
          test.equality error.code, 404
          test.done()


  "can’t delete a record that doesn’t exist": (test) ->
    test.expect 1
    storage = new ElasticStorage
    storage.delete "test/records/0", (error) ->
      test.equality error.code, 404
      test.done()


  "record path pattern matches typical record paths": (test) ->
    storage = new ElasticStorage
    test.assert storage.RECORD_ADDRESS_PATTERN.test "business/memos/a"
    test.assert storage.RECORD_ADDRESS_PATTERN.test "business/memos/ABC"
    test.assert storage.RECORD_ADDRESS_PATTERN.test "business/memos/0"
    test.assert storage.RECORD_ADDRESS_PATTERN.test "business/memos/123"
    test.assert storage.RECORD_ADDRESS_PATTERN.test "business/memos/ABC-123_"
    test.done()


  "record path pattern does not match collection paths": (test) ->
    storage = new ElasticStorage
    test.equality no, storage.RECORD_ADDRESS_PATTERN.test ""
    test.equality no, storage.RECORD_ADDRESS_PATTERN.test "_all"
    test.equality no, storage.RECORD_ADDRESS_PATTERN.test "business/memos"
    test.equality no, storage.RECORD_ADDRESS_PATTERN.test "public,private/memos"
    test.done()
