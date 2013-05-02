PORT = Number(process.env.PORT ? 8081)

app = require './lib/app'

server = require('http').createServer app
if isNaN(PORT) then server.listen() else server.listen PORT
console.log "Server running on :#{server.address().port} in #{app.settings.env} mode"
