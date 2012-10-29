# Exports `index` and `search` – all you need to dethrone Google.
{extend} = require "underscore"

module.exports = 
  # # Index a record at this `address` with these `attributes`
  #
  # `address` should be a string in the form `"index/collection/id"`.
  #
  # Dispatches a [document indexing request](http://www.elasticsearch.org/guide/reference/api/index_.html) 
  # that `PUT`s `attributes` in the location defined by `address`.
  # If a record already exists at the `address` it will be replaced.
  #
  # Expect `callback(error, ...)` when the request is complete.
  # `error` is `undefined` if the operation was successful.

  index: (address, attributes, callback=@defaultCallback) ->
    @request "PUT",
      path: address
      body: attributes
      done: (error, output, response, request) -> 
        callback error, undefined, response, request

  # # Search `address` for records that match `criteria`
  #
  # `address` specifies the collections that should be searched.
  # For example: an `address` of `"business/memos"` searches records in the `"memos"` collection of the `"business"` index.
  # Addresses that expand to multiple indices and/or collections are acceptable too. 
  # Review [elasticsearch’s multi-index syntax](http://www.elasticsearch.org/guide/reference/api/multi-index.html) for details.
  #
  # Define your `criteria` with the [query DSL](http://www.elasticsearch.org/guide/reference/query-dsl/).
  # Common `criteria` include `query`, `highlights`, `filter`, `size`, `from` and `sort`.
  # Pass an empty `criteria` argument to get all the records at a particular `address`.
  #
  # Dispatches a [document search request](http://www.elasticsearch.org/guide/reference/api/search/).
  #
  # Expect `callback(error, hits, ...)` when the request is done. 
  # `hits` is a list that’s been augmented with the `total` number of hits and the `highScore`.
  # Each hit in the list contains `score`, `collection`, `record` and `highlights`.

  search: (address, criteria, callback=@defaultCallback) ->
    @request "POST",
      path: "#{address}/_search"
      body: criteria
      done: (error, output, response, request) ->
        if output
          hits = for {_id, _score, _source, _type, highlight} in output.hits.hits
            score: _score
            collection: _type
            record: extend(_source, {id: _id})
            highlights: highlight
          hits.total = output.hits.total
          hits.highScore = output.hits.max_score
        callback error, hits, response, request
