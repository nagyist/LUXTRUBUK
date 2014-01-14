pg = require 'pg'
constring = require('./config.LOCAL').constring

clientConnect = (next = ()->) ->
  pg.connect constring, (err, client, done) ->
    if err
      console.log "clientConnect ERROR"
      console.log err
      return next err
    next(err, client)

runQuery = (err, query, next = ()->) ->
  clientConnect (err, client) ->
    client.query query, (err, result) ->
      if err
        console.log err
        return next err
      client.end()
      console.log "QUERY #{query}"
      console.log "QUERY RESULTS #{JSON.stringify result.rows}"
      next(err, result)
  

#getRandomGameId = (err, next = ()->) ->
  #offset = "random() * (SELECT count(*) FROM clues_flat)"
  #query = "SELECT game FROM clues_flat OFFSET #{offset} LIMIT 1"
  #runQuery err, query, (err, result) ->
      #if err
        #console.log err
        #return next err
      #client.end()
      #console.log "RANDOM GAME ID #{result.rows[0].game}"
      #next(err, result.rows[0].game)

getGame = (err, gamehash, next = ()->) ->
  return if not gamehash?
  fields = "clue, answer, value, category, round, cluehash"
  query ="SELECT #{fields} FROM clues_flat WHERE gamehash='#{gamehash}'
    ORDER BY round, category, value"
  runQuery err, query, (err, result) ->
    if err
      console.log "getGAME ERROR"
      console.log err
      return err
    next err, result.rows

getRandomGame = (err, next = ()->) ->
  getRandomGameId (gameId) ->
    getGame gameId, next

getRandomGameHash = (err, next = ()->) ->
  offset = "random() * (SELECT count(*) FROM clues_flat)"
  query = "SELECT gamehash FROM clues_flat OFFSET #{offset} LIMIT 1"
  runQuery err, query, (err, result) ->
    console.log "gRGH: #{JSON.stringify result.rows}"
    next err, result.rows[0].gamehash

module.exports =
  getGame: getGame
  getRandomGame: getRandomGame
  getRandomGameHash: getRandomGameHash
