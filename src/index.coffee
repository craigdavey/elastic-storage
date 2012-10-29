# `ElasticStorage` instances provide methods to communicate with an [elasticsearch](http://www.elasticsearch.org) 
# cluster from a [Node](http://nodejs.org/) programming environment. Require the 
# constructor in your program and then construct a new `storage` instance to work 
# with, like this:
#
#     ElasticStorage = require "elastic_storage"
#     storage = new ElasticStorage
#
# Instances are configured to use an elasticsearch cluster at `http://localhost:9200/` 
# by default. You can configure a different network address with the `host` and 
# `port` options when you construct a new instance:
#
#     storage = new ElasticStorage
#       host: "elasticsearch.host"
#       port: 8080
#

HTTP     = require "http"
{extend} = require "underscore"

class ElasticStorage
  module.exports = this
  
  host: "localhost"

  port: 9200

  timeout: 0

  constructor: (options={}) ->
    extend this, options

  # ##  [Index records and search them out](core.coffee)
  #
  #     storage.index address, attributes, ƒ
  #     storage.search address, criteria, ƒ
  #
  extend @prototype, require("./core")

  # ##  [Read and write records like a conventional database](crud.coffee)
  #
  #     storage.read address, ƒ
  #     storage.read address, criteria, ƒ
  #     storage.create address, attributes, ƒ
  #     storage.update address, attributes, ƒ
  #     storage.delete address, ƒ
  #
  extend @prototype, require("./crud")

  # ##  [Administer the indices in your cluster](indices.coffee)
  #
  #     storage.init address, ƒ
  #     storage.drop address, ƒ
  #     storage.refresh address, ƒ
  #     storage.has address, ƒ
  #     storage.fetchIndices ƒ
  #
  extend @prototype, require("./indices")

  # ##  [Aliases make it easy to go from one index to the next](aliases.coffee) !!!
  #
  #     storage.migrate alias, currentIndex, nextIndex, ƒ
  #     storage.createAlias alias, ƒ
  #     storage.deleteAlias alias, ƒ
  #     storage.fetchAliases ƒ
  #
  extend @prototype, require("./aliases")

  # ##  [Utility to iterate over all records within an address](scan.coffee)
  # 
  #     storage.scan address,
  #       forEach: (record) ->
  #       done: ƒ
  #
  extend @prototype, require("./scan")

  # ##  [Synchronize with Backbone](backbone_sync.coffee)
  # 
  #     Backbone.sync = ElasticStorage.setupBackboneSync()
  #
  extend this, require("./backbone_sync")

  # ---
  
  # All HTTP traffic is routed through the `request` method.
  # It constructs a request defined by `method` and `options` and prepares handlers for success and error conditions.
  request: (method, options={}) ->
    
    {path, body, done} = options
    request = HTTP.request {method, path, @host, @port}
    request.setHeader "accept", "application/json"
    if typeof body is "object" then body = JSON.stringify(body) 
    if body then request.write body

    # Stop the request if it exceeds the time limit. `request.abort()` triggers
    # an `"error"` event that will be handled in the next section.
    request.setTimeout @timeout, ->
      request.exceededTimeLimit = true
      request.abort()

    # When a transport error occurs, first, clarify the `error.message` if the event was triggered by a timeout.
    # 
    # If the connection was refused or reset call `done(error, ...)` with an `error` that summarizes the problem.
    # In this case the `output` and `response` arguments are both `undefined` because the `error` occured before a `response` arrived.
    #
    # Any other transport error halts program execution.
    request.on "error", (error) =>
      console.error error
      
      if request.exceededTimeLimit
        error.message = "Timeout occured after #{@timeout}ms — #{error.message}"
      switch error.code
        when "ECONNREFUSED", "ECONNRESET"
          error = @ConnectionError(error)
          done(error, undefined, undefined, request)
        else
          throw @UnexpectedError(error)

    # Buffer response data as it arrives and `JSON.parse` when it’s complete.
    #
    # Calls `done(undefined, output, ...)` when the response is OK.
    # `output` is the parsed response data.
    #
    # Calls `done(error, undefined, ...)` when the response is a failure.
    # `error.message` is usually a notice from the cluster that describes the problem.
    # `error.code` contains the HTTP status code.
    request.on "response", (response) =>
      buffer = new Buffer 0
      response.on "data", (data) =>
        buffer = Buffer.concat [buffer, data]
      response.on "end", =>
        if response.headers["content-type"].split(";")[0] is "application/json"
          output = if buffer.length is 0 then {} else JSON.parse(buffer.toString())
        else
          output = {error: buffer.toString()} if response.statusCode >= 400

        if response.statusCode < 400
          done(undefined, output, response, request)
        else
          error = @ResponseError(output.error, response.statusCode)
          console.error error
          done(error, undefined, response, request)

    # Dispatch the request.
    request.end()

    # Returns a friendly description of the request.
    "#{request.method} /#{request.path}"

  # ---

  # Construct an error that summarizes a connection problem.
  ConnectionError: (originalError) ->
    intro = "ElasticStorage can’t connect to http://#{@host}:#{@port}/"
    error = new Error "#{intro} — #{originalError.message}"
    error.code = originalError.code
    error.syscall = originalError.syscall
    return error

  # Construct an error that summarizes an unexpected occurence.
  UnexpectedError: (originalError) ->
    intro = "Unexpected error occured"
    error = new Error "#{intro} — #{originalError.message}"
    error.code = originalError.code
    error.syscall = originalError.syscall
    return error

  # Construct an error that summarizes a HTTP failure response.
  ResponseError: (message, code) ->
    error = new Error message
    error.code = code
    return error

  # `defaultCallback` is used when a storage method is called without a callback
  # argument. It’s provided for convenience when you’re working in the console.
  defaultCallback: (error, output, response, request) ->
    status = if response then HTTP.STATUS_CODES[response.statusCode] else response
    console.info status
    console.info output if output
    console.error error if error
