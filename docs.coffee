connect    = require "connect"
doccomatic = require "doccomatic"
{execFile} = require "child_process"

# Create a server.
server = connect.createServer()

# Configure the server to use Doccomatic middleware.
server.use "/docs", doccomatic()

# Ask the server to listen on port 3210.
server.listen(3210)

# Give directions to strangers.
console.log "Opening http://localhost:3210/docs/doccomatic.coffee"
