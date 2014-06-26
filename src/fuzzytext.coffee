FuzzySearcher = require "fuzzy-text-search-h"
Promise = require('es6-promise').Promise

class OnePhaseFuzzyStrategy

  name: "one-phase fuzzy"
  priority: 70

  constructor: ->
    @textFinder = new FuzzySearcher()

  configure: (@manager) ->

  createAnchor: (selectors) ->
    new Promise (resolve, reject) =>

      # Look up the saved quote
      quote = @manager._getQuoteForSelectors? selectors

      unless quote
        reject "No TextQuoteSelector found."
        return

      # For too short quotes, this strategy is bound to return false positives.
      # See https://github.com/hypothesis/h/issues/853 for details.
      unless quote.length >= 32
        reject "can't use this strategy for quotes this short"
        return

      # Get a starting position for the search
      posSelector = @manager._findSelector selectors, "TextPositionSelector"
      expectedStart = posSelector?.start

      # Get d-t-m into a ready state
      @manager._document.prepare("anchoring").then (s) =>
        try

          # Get full document length
          len = s.getCorpus().length

          # If we don't have the position saved, start at the middle of the doc
          expectedStart ?= Math.floor(len / 2)

          # Do the fuzzy search
          options =
            matchDistance: len * 2
            withFuzzyComparison: true

          result = @textFinder.searchFuzzy s.getCorpus(), quote, expectedStart,
            false, options

          # If we did not got a result, give up
          unless result.matches.length
            reject "fuzzy found no match for '" + quote + "' @ " + expectedStart
            return

          # here is our result
          match = result.matches[0]
#          console.log "1-phase fuzzy found match at: [" + match.start + ":" +
#            match.end + "]: '" + match.found + "' (exact: " + match.exact + ")"

          # OK, we have everything
          # Create a TextPositionAnchor from this data
          anchor =
            type: "text position"
            start: match.start
            end: match.end
            startPage: s.getPageIndexForPos match.start
            endPage: s.getPageIndexForPos match.end
            quote: match.found
          unless match.exact
            anchor.diffHTML = match.comparison.diffHTML
            anchor.diffCaseOnly = match.exactExceptCase
          resolve anchor
        catch error
          reject error

class TwoPhaseFuzzyStrategy

  name: "two-phase fuzzy"
  priority: 60

  constructor: ->
    @textFinder = new FuzzySearcher()

  configure: (@manager) ->

  createAnchor: (selectors) ->
    new Promise (resolve, reject) =>

      # Fetch the quote and the context
      quoteSelector = @manager._findSelector selectors, "TextQuoteSelector"
      unless quoteSelector
        reject "no TextQuoteSelector found", true
        return

      prefix = quoteSelector.prefix
      suffix = quoteSelector.suffix
      quote = quoteSelector.exact

      # No context, to joy
      unless prefix and suffix
        reject "prefix and suffix is required"
        return

      # Fetch the expected start and end positions
      posSelector = @manager._findSelector selectors, "TextPositionSelector"
      expectedStart = posSelector?.start
      expectedEnd = posSelector?.end

      @manager._document.prepare("anchoring").then (s) =>
        try
          options =
            contextMatchDistance: s.getCorpus().length * 2
            contextMatchThreshold: 0.5
            patternMatchThreshold: 0.5
            flexContext: true
          result = @textFinder.searchFuzzyWithContext s.getCorpus(),
            prefix, suffix, quote,
            expectedStart, expectedEnd, false, options

          # If we did not got a result, give up
          unless result.matches.length
            reject "fuzzy match found no result for '" + quote + "' @ " +
              expectedStart + "."
            return

          # here is our result
          match = result.matches[0]
#          console.log "2-phase fuzzy found match at: [" + match.start + ":" +
#            match.end + "]: '" + match.found + "' (exact: " + match.exact + ")"

          # OK, we have everything
          # Create a TextPositionAnchor from this data
          anchor =
            type: "text position"
            start: match.start
            end: match.end
            startPage: s.getPageIndexForPos match.start
            endPage: s.getPageIndexForPos match.end
            quote: match.found
          unless match.exact
            anchor.diffHTML = match.comparison.diffHTML
            anchor.diffCaseOnly = match.exactExceptCase
          resolve anchor
        catch error
          reject error

module.exports =
  strategy:
    onePhase: OnePhaseFuzzyStrategy
    twoPhase: TwoPhaseFuzzyStrategy

