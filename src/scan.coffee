# Exports the `scan` method. Used to read through all the records in one or many collections.

{extend} = require "underscore"
{waterfall} = require "async"

# # Scan all records in the collection(s) at `address`
#
# `address` specificies the collection(s) that should be scanned.
#
# `options` defines two functions:
#
# - `forEach` is an iterator that accepts a `record` argument.
#
# - `done` is called when the scan is complete.

exports.scan = (address, options={}) ->
  new Scan this, address, options
        
class Scan
  size: 10
  total: 0
  
  constructor: (@storage, @path, options={}) ->
    extend this, options
    waterfall [
      (ƒ) => @getFirstScrollId ƒ
      (scrollId, ƒ) => @processDocs scrollId, ƒ
    ], @done
  
  forEach: (doc) -> 
    console.log "#{doc["_type"]}/#{doc["_id"]}"

  done: (error, total) => 
    console.error error if error?
    console.log "Finished scan of #{total} docs."

  getFirstScrollId: (callback) ->
    @storage.request
      method: "POST"
      path: "#{@path}/_search?search_type=scan&scroll=10m&size=#{@size}"
      done: (error, response) -> callback(error, response["_scroll_id"])

  processDocs: (scrollId, callback) ->
    @storage.request
      method: "POST"
      path: "/_search/scroll?scroll=10m"
      body: scrollId
      done: (error, response) =>
        hits = response?["hits"]["hits"]
        scrollId = response?["_scroll_id"]

        if hits.length > 0
          @total = @total + hits.length
          @forEach doc for doc in hits
        
        if scrollId? and hits.length isnt 0
          @processDocs scrollId, callback
        else
          callback(error, @total)
