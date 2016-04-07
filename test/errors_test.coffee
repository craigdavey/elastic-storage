{ElasticStorage} = require "./test_helper"

module.exports =
  "Connection reset error": (test) ->
    storage = new ElasticStorage port: 0
    storage.init "test", (error) ->
      test.assert error instanceof Error
      test.equality error.message, """
        ElasticStorage can’t connect to http://localhost:0/ — socket hang up
      """
      test.equality error.code, "ECONNRESET"
      test.done()


  "Connection refused error": (test) ->
    storage = new ElasticStorage port: 1
    storage.init "test", (error) ->
      test.assert error instanceof Error
      test.equality error.message, """
        ElasticStorage can’t connect to http://localhost:1/ — connect ECONNREFUSED
      """
      test.equality error.code, "ECONNREFUSED"
      test.done()


  "Connection timeout error": (test) ->
    storage = new ElasticStorage timeout: 1
    storage.init "test", (error) ->
      test.assert error instanceof Error
      test.equality error.message, """
        ElasticStorage can’t connect to http://localhost:9201/ — Timeout occured after 1ms — socket hang up
      """
      test.equality error.code, "ECONNRESET"
      test.done()


  "Missing index error": (test) ->
    storage = new ElasticStorage
    storage.drop "test", (error) ->
      test.assert error instanceof Error
      test.equality error.message, """
        IndexMissingException[[test] missing]
      """
      test.equality error.code, 404
      test.done()
