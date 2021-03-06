_ = require 'lodash'

log = (msg) ->
  console.log.call(console, msg)

getClues = (gamehash, next)->
  gameKey = "game-" + gamehash
  localGame = localStorage.getItem(gameKey)
  return next(JSON.parse(localGame)) if localGame
  $.getJSON "/data/games/#{gamehash}.json", (data)->
    localStorage.setItem "game-" + gamehash, JSON.stringify(data)
    next data

getRandomHash = (next)->
  $.ajax
    url: 'api/game/randomHash'
    success: (data) ->
      next(data)

sortToMiddle = (arr, sortByFn = _.identity)->
  sorted = _.sortBy(arr, sortByFn)
  head = _.filter sorted, (el, index, arr)->
    (index % 2) == 0
  tail = _.difference(sorted, head).reverse()
  out = head.concat tail
  out

sortToMiddleByLen = (arr) ->
  sortToMiddle arr, (item)->
    item.length
 
sortCatGroup = (arr)->
  arr = sortToMiddle arr, (item)->
    item.cat.length

cluesByRound = (clues, roundNum)->
  _.filter clues, 'round': roundNum

cluesByCategory = (clues, category)->
  _.filter clues, 'category': category

ucFirst = (str)->
  str.charAt(0).toUpperCase() + str.slice(1)


defaultPlayers = ()->
  Hortence: 0
  Edmund: 0
  Aloisius: 0

class Game
  constructor: (@clues, @players = defaultPlayers())->
    @gamehash = @clues[0].gamehash
    @_round = 0
    return this

  getClue: (cluehash)->
    if not cluehash?
      return @clues[0]
    
    clue = _.find @clues, cluehash: cluehash
    clue

  pickClue: (cluehash)->
    clue = @getClue cluehash
    clue.picked = true
    clue

  # Get clues from the current round
  curClues: ()->
    cluesByRound(@clues, @_round)

  curCluesByCat: ()->
    clues = @curClues()
    a = _.chain(clues)
      .groupBy('category')
      .mapValues((v,k)->
        cat: k
        clues: v
      )
      .toArray()
      .tap(sortCatGroup)
      .valueOf()
    #sortCatGroup(a)

  updateGame: ()->
    cluesLeft = _.filter(@curClues(), {picked: undefined}).length
    if cluesLeft <= 0
      @_round++
      return true
    false

  getPlayers: ()->
    @players

  playerResult: (player, answer, value)->
    # Return if answer is neither 'right' nor 'wrong'
    return if not answer
    @players[player] += value * (if answer == 'right' then 1 else -1)

  reportAnswers: (results, value) ->
    for own k,v of results
      @playerResult k, v, value
    @updateGame()

  reportFinalAnswers: (answers, bids)->
    for own k,v of answers
      @playerResult k, v, bids[k]
    @round 4
    return true

  # Gets the top score
  getTopScore: ()->
    topScoreFn = (acc, val, key)->
      if val > acc then val else acc
    _.reduce @players, topScoreFn, 0

  # Return all players with score equal to the top score
  getLeaders: ()->
    topScore = @getTopScore()
    _.chain @players
      .pairs()
      .filter (pair)->
        pair[1] == topScore
      .map (pair)-> pair[0]
      .value()

  start: ()->
    @_round = 1

  round: (round)->
    if round then @_round = round
    @_round


module.exports = ()->
  {sortToMiddle, getRandomHash, getClues, sortToMiddleByLen,
    cluesByRound, Game}
