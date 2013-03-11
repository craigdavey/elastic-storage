# Generates a `Backbone.sync` method bound to a private storage instance.
# Accepts the same `options` as `ElasticStorage`:
#
#     Backbone.sync = ElasticStorage.setupBackboneSync
#       host: "storage.example.com"
#       port: 9200
#
# If your model (or collection) defines a `storageAddress` it will be used
# as the `address` argument for storage methods. If there is no `storageAddress`
# the object’s `url` will be used instead. You should probably define both
# methods if your models are used in multiple environments. Use `model.url()`
# on the client side and `model.storageAddress()` on the server:
#
#     class Memo extends Backbone.Model
#       storageAddress: ->
#         "app/#{@url()}"
#
#       url: ->
#         if @isNew()
#           "memos"
#         else
#           "memos/#{@id}"
#
# Define `criteria` on any collections that should be reduced or sorted. 
# Specify your `criteria` with the [query DSL](http://www.elasticsearch.org/guide/reference/query-dsl/).
#
#     class ArchivedMemos extends Backbone.Collection
#       storageAddress: ->
#         "app/memos"
#
#       criteria: ->
#         filter: {exists: {field: "archived_at"}}
#         sort: {"updated_at": {order:"desc"}}
#         size: 100
#
module.exports.setupBackboneSync = (options={}) ->
  if options instanceof this
    storage = options
  else
    storage = new this options
  
  return (method, object, options={}) ->
    address = getValue(object, "storageAddress") or getValue(object, "url")
    
    input = switch method
      when "read"
        getValue(object, "criteria")
      when "create", "update"
        object.toJSON()
    
    storage[method] address, input, (error, output, response, request) ->
      if error is undefined
        if options.success then options.success(object, output, options)
        object.trigger("sync", object, output, options)
      else
        if options.error then options.error(object, request, options)
        object.trigger("error", object, request, options)


getValue = (object, member) ->
  if object[member]?.call then object[member]() else object[member]
