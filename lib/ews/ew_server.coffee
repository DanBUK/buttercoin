stump = require('stump')

WebsocketListener = require('./ws_listener')
EngineProtocol = require('./e_protocol')

EngineServer = require('../engine_server')
helpers = require('enkihelpers')

module.exports = class EngineWebsocketServer extends EngineServer
  start: =>
    @connection_map = {}
    @closed = false

    @pce.start().then =>
      @listener = new WebsocketListener( { 
          wsconfig: {port: 6150}
          protocol_factory: @new_connection
      } )
      @listener.listen()

  stop: =>
    if @closed
      throw Error('ALREADY CLOSED')

    @closed = true
    @info 'SHUTTING DOWN'
    cop = helpers.extend({}, @connection_map)
    @connection_map = {}
    return @listener.close().then =>
      @info 'LISTENER CLOSED'
      Q.all( [y.disconnect() for x,y of cop] ).then =>
        @info 'ALL CONNS CLOSED'
        return true

  new_connection: (connection) => # this is our protocol factory
    @connection_map[ connection.conncounter ] = connection
    protocol = new EngineProtocol({
      pce: @pce
      connection_lost: @connection_lost
      send_all: @send_all
    })
    protocol.start(connection)

  connection_lost: (connection) =>
    delete @connection_map[connection.conncounter]

  send_all: ( obj ) =>
    @info 'SEND ALL'
    for x, y of @connection_map
      y.send_obj obj
