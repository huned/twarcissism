_u = require 'underscore'
_s = require 'underscore.string'
express = require 'express'
http = require 'http'
app = express.createServer()
stopwords = require('./stopwords').stopwords

app.get '/:screen_name', (request, response) ->
  follower_options =
    host: 'api.twitter.com'
    path: '/1/followers/ids.json?screen_name=' + request.params.screen_name

  http.get follower_options, (follower_id_response) ->

    counts = {}

    follower_ids = ''
    follower_id_response.on 'data', (follower_id_chunk) ->
      follower_ids += follower_id_chunk

    follower_id_response.on 'end', () ->
      lookup_options =
        host: 'api.twitter.com'
        path: '/1/users/lookup.json?user_id=' + eval(follower_ids).join(',')

      http.get lookup_options, (lookup_response) ->
        lookup_data = ''
        lookup_response.on 'data', (lookup_response_chunk) ->
          lookup_data += lookup_response_chunk
        lookup_response.on 'end', () ->
          # clean up description
          descs = _u.compact _u.pluck(eval(lookup_data), 'description')
          words = _u.map descs, (desc) ->
            _u.map _s.words(desc.toLowerCase()), (word) ->
              _s.trim(word.match(/[A-Za-z]+(?:\w|\d|')+/) || '')
          words = _u.compact _u.flatten(words)

          # remove stopwords
          words = _u.select words, (word) ->
            stopwords.indexOf(word) < 0

          # count stuff
          _u.each words, (word) ->
            counts[word] ||= 0
            counts[word]++

          popular_words = _u.sortBy _u.keys(counts), (word) ->
            -counts[word]

          results = _u.reduce popular_words, (hash, word) ->
            hash[word] = counts[word] / eval(follower_ids).length * 100
            hash
          , {}

          response.send results

console.log 'listening 3000'
app.listen 3000
