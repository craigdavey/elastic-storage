# Exports `create`, `read`, `update` and `delete` methods that mimic the cruddy 
# operations normally found in old-school databases.

{extend} = require "underscore"

module.exports =

  # # Create a record of these `attributes` in the collection at `address`
  #
  # `address` should be a string in the form `"index/collection"`.
  #
  # `attributes` define the record. `"created_at"` and `"updated_at"` attributes
  # are set to the current time automatically.
  #
  # Dispatches a [document indexing request](http://www.elasticsearch.org/guide/reference/api/index_.html)
  # and takes `_id` from the response to form the address of the record. 
  # Then reads the record and passes it to your `callback`.
  #
  # Expect `callback(error, record, ...)` when the request is complete. 
  # `record` is an updated version of `attributes` that includes `"id"`, 
  # `"created_at"` and `"updated_at"`.

  create: (address, attributes, callback=@defaultCallback) ->
    attributes["created_at"] = "now"
    attributes["updated_at"] = "now"
    @setTime attributes
    
    @request "POST",
      path: address
      body: attributes
      done: (error, output, response, request) =>
        if output
          @read "#{address}/#{output._id}", callback
        else
          callback error, undefined, response, request


  # # Read one record, or many records, from an `address`
  #
  # Pass an `address` in the form `"index/collection/id"` to read one record.
  # Dispatches a [document retrieval request](http://www.elasticsearch.org/guide/reference/api/get.html) 
  # and constructs a `record` from the `_id` and `_source` members of the response.
  # Expect `callback(error, record, ...)` when the request is complete.
  # `record` is `undefined` when there is an `error`.
  #
  # Pass an `address` in the form `"index/collection"` to read a collection of records.
  # Or use [a complex address](http://www.elasticsearch.org/guide/reference/api/search/indices-types.html) to read records from multiple collections.
  # Dispatches a [document search request](http://www.elasticsearch.org/guide/reference/api/search/)
  # and assembles a list of `records` from the hits in the response.
  # Expect `callback(error, records, ...)` when the request is complete.
  # `records` is `undefined` when there is an `error`.
  #
  # `criteria` is ignored when you read a single record and its optional when you read a collection.
  # If you’re not using `criteria` you can put `callback` in its place instead of passing a `null` argument to `read`.

  read: (address, criteria, callback=@defaultCallback) ->
    if criteria instanceof Function
      callback = criteria
      criteria = undefined

    if address.match @RECORD_ADDRESS_PATTERN
      @request "GET",
        path: address
        done: (error, output, response, request) ->
          record = if output
            extend {id: output._id}, output._source
          callback error, record, response, request
    else
      @request "POST",
        path: "#{address}/_search"
        body: criteria
        done: (error, output, response, request) ->
          records = if output
            extend {id: _id}, _source for {_id, _source} in output.hits.hits
          callback error, records, response, request


  # # Update the record at `address` with these `attributes`
  #
  # `address` should be a string in the form `"index/collection/id"`.
  #
  # `attributes` define the record. The `"updated_at"` attribute is set to the
  # current time automatically.
  #
  # Dispatches a [document indexing request](http://www.elasticsearch.org/guide/reference/api/index_.html) 
  # to save the `attributes`. Then reads the updated `record` and sends it to
  # your `callback`.
  #
  # Expect `callback(error, record, ...)` when the request is complete.
  # `record` is `undefined` if an `error` occurred. 

  update: (address, attributes, callback=@defaultCallback) ->
    attributes["updated_at"] = "now"
    @setTime attributes
    
    @request "PUT",
      path: address
      body: attributes
      done: (error, output, response, request) =>
        if error is undefined
          @read address, callback
        else
          callback error, undefined, response, request


  # # Delete the record located at this `address`
  #
  # `address` should be a string in the form `"index/collection/id"`.
  #
  # `callback` may be passed as the second or third argument.
  # Support for passing it as the third argument is in place to maintain symmetry with the other CRUD methods.
  #
  # Dispatches a [document deletion request](http://www.elasticsearch.org/guide/reference/api/delete.html).
  # Guards against deletion requests with blank addresses because they could destroy all the data in your cluster.
  #
  # Expect `callback(error, ...)` when the request is complete.
  # If `error` is `undefined` the operation was successful.

  delete: (address, callback=@defaultCallback) ->
    callback = arguments[2] or callback
    
    if address.trim() is ""
      callback new Error """
        ElasticStorage::delete received a blank address. Refused to send a 
        DELETE request because it could erase all your indices.
        """
    else
      @request "DELETE",
        path: address
        done: (error, output, response, request) ->
          callback error, undefined, response, request


  # ---

  # Matches `"index/collection/id"` formated `address` arguments that refer to one record. 
  # Used by the `read` method to decide when to read one record vs. many records.
  RECORD_ADDRESS_PATTERN: ///
    ^
    [a-zA-Z0-9_-]+ # index
    /
    [a-zA-Z0-9_-]+ # collection
    /
    [a-zA-Z0-9_-]+ # id
    $
  ///

  # Attribute names that match this pattern are time attributes.
  TIME_ATTRIBUTE_PATTERN: ///
    ^
    [a-z_]+_at
    $
  ///

  # Set time attributes with a value of `"now"` to the current time. Called by the`create` 
  # and `update` methods to populate `"created_at"` and `"updated_at"` attributes.
  setTime: (attributes) ->
    pattern = @TIME_ATTRIBUTE_PATTERN
    timestamp = (new Date).toJSON()
    for name, value of attributes when name.match(pattern) and value is "now"
      attributes[name] = timestamp 
