{ElasticStorage} = require "./test_helper"

exports["Storage::scan"] = (test) ->
  storage = new ElasticStorage
  test.ok storage.scan
  test.done()
