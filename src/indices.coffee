# Exports `init`, `drop`, `refresh`, `has` and `fetchIndices`.

module.exports =

  # # Initialize a blank index at this `address`
  #
  # `address` defines the location of the index. Use a string that will work 
  # well in HTTP URLs. `address` may not contain `/` or `,` characters and 
  # should not begin with `_`.
  #
  # Dispatches an [index creation request](http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html).
  #
  # Expect `callback(error, ...)` when the response is ready. The index was 
  # created successfuly if `error` is `undefined`.

  init: (address, callback=@defaultCallback) ->
    @request "PUT",
      path: address
      done: (error, output, response, request) ->
        callback error, undefined, response, request


  # # Drop the index at this `address`
  #
  # Dropping an index permanently erases its mapping and all of its records.
  # `address` specifies the index or indices that should be destroyed.
  # Use `"_all"` to drop everything – but be careful – there is no undo.
  #
  # Dispatches an [index deletion request](http://www.elasticsearch.org/guide/reference/api/admin-indices-delete-index.html).
  # Guards against sending deletion requests with a blank `address` because
  # they could destroy all the data in your cluster.
  #
  # Expect `callback(error, ...)` when the request is done. The index was 
  # successfuly destroyed if `error` is `undefined`.

  drop: (address, callback=@defaultCallback) ->
    if address.trim() is ""
      callback new Error """
        ElasticStorage::drop received a blank address. Use the "_all" 
        index if you really want to erase all of your indices.
        """
    else
      @request "DELETE",
        path: address
        done: (error, output, response, request) ->
          callback error, undefined, response, request

  # # Refresh the index at this `address`
  #
  # The cluster refreshes your indices automatically but ocasionaly you’ll
  # need to do it yourself (in unit tests for example).
  #
  # `address` specifies the index or indices that should be refreshed.
  #
  # Dispatches an [index refresh request](http://www.elasticsearch.org/guide/reference/api/admin-indices-refresh.html).
  #
  # Expect `callback(error, ...)` when the request is done. If `error` is
  # `undefined` the operation was successful.

  refresh: (address, callback=@defaultCallback) ->
    @request "POST",
      path: "#{address}/_refresh"
      done: (error, output, response, request) ->
        callback error, undefined, response, request


  # # Is there an index at this `address`?
  #
  # Dispatches an [index exists request](http://www.elasticsearch.org/guide/reference/api/admin-indices-indices-exists.html).
  #
  # Expect `callback(error, exists, ...)` when the answer is known. `exists` is
  # `true` when the index was found and is `false` when it was not found.

  has: (address, callback=@defaultCallback) ->
    @request "HEAD",
      path: address
      done: (error, output, response, request) ->
        if error?.code is 404
          exists = no
          error  = undefined
        else
          exists = response?.statusCode is 200
        callback error, exists, response, request


  # # Fetch a list of indices (with their aliases)
  #
  # Dispatches an [index aliases request](http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html) 
  # and converts the response into a list of `indices`. Each object in the list
  # contains `id` and `alias` members. `id` is the address of the index. `alias`
  # is the address of its alias (if it has one). `indices` is a suitable source
  # of data for a `Backbone.Collection` that models all the indices in your cluster.
  #
  # Expect `callback(error, indices, ...)` when the list is ready.
  #
  # Although it is perfectly valid to have one index with multiple aliases, it
  # makes your system more difficult to understand. To keep things simple 
  # `ElasticStorage` assumes each index will only be assigned to a single alias.
  # Feel free to replace this method if you require support for more complexity.

  fetchIndices: (callback=@defaultCallback) ->
    @request "GET",
      path: "_aliases"
      done: (error, output, response, request) ->
        indices = if output
          {id, alias: Object.keys(value.aliases)[0]} for id, value of output
        if indices then indices.sort (a, b) -> a.id > b.id
        callback error, indices, response, request
