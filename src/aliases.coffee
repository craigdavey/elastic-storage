module.exports =

  migrate: (alias, currentIndex, newIndex, callback=@defaultCallback) ->
    alias = alias.toString()
    @modifyAliases [
      remove: {alias, index: currentIndex}
      add:    {alias, index: newIndex}
    ], callback


  createAlias: (alias, index, callback=@defaultCallback) ->
    alias = alias.toString()
    @modifyAliases [add: {alias, index}], callback


  deleteAlias: (alias, index, callback=@defaultCallback) ->
    alias = alias.toString()
    @modifyAliases [remove: {alias, index}], callback


  getAliases: (callback=@defaultCallback) ->
    @request "GET",
      path: "_aliases"
      done: (error, response, statusCode) ->
        aliases = []
        map = {}
        if response?
          for index of response
            for alias in Object.keys response[index].aliases
              if map[alias] is undefined
                aliases.push alias
                map[alias] = []
              map[alias].push index
        callback error, aliases, map


  modifyAliases: (actions, callback=@defaultCallback) ->
    @request "POST",
      path: "_aliases"
      body: {actions}
      done: (error, response) ->
        callback error, response?["acknowledged"]?
