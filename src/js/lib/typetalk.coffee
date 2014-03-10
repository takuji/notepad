http = require 'http'
querystring = require 'querystring'

class Typetalk
  constructor: (options)->
    @client_id = options.client_id
    @client_secret = options.client_secret

  getAuthorizationUrl: (options)->
    params =
      client_id: @client_id
      redirect_url: options.redirect_url
    "https://typetalk.in/oauth2/authorize?#{querystring.stringify(params)}"

module.exports = Typetalk
