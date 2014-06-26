FuzzySearcher = require "fuzzy-text-search-h"
Promise = require('es6-promise').Promise

class OnePhaseFuzzyStrategy

  name: "one-phase fuzzy"
  priority: 70

  constructor: ->
    @textFinder = new FuzzySearcher()

    console.log "My text finder is", @textFinder

  createAnchor: (selectors) ->
    null
    new Promise (resolve, reject) ->
      reject "not implemented yet"

class TwoPhaseFuzzyStrategy

  name: "two-phase fuzzy"
  priority: 60

  constructor: ->
    @textFinder = new FuzzySearcher()

  createAnchor: (selectors) ->
    null

module.exports =
  strategy:
    onePhase: OnePhaseFuzzyStrategy
    twoPhase: TwoPhaseFuzzyStrategy

