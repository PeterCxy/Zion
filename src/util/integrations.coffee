# Utilities for Integration Managers (IMs)
# Partially based on matrix-react-sdk/src/utils/WidgetUtils.js
import React from "react"
import { URL } from "react-native-url-polyfill"
import AsyncStorage from '@react-native-community/async-storage'

# Get widgets set by the current user
# from the MatrixClient instance
export getUserWidgets = (client) ->
  client.getAccountData('m.widgets')?.getContent() ? {}

export getUserWidgetsArray = (client) ->
  Object.values getUserWidgets client

# Get the current sticker widgets for the current user
# There can be multiple
export getStickerWidgets = (client) ->
  getUserWidgetsArray(client).filter (widget) ->
    widget.content? and widget.content.type is 'm.stickerpicker'

# Get the URL for displaying the widget
export getWidgetURL = (widget, scalarToken) ->
  url = widget.content.url + "?"
  url += "widgetId=#{encodeURIComponent widget.id}"
  # Fake parent url
  url += "&parentUrl=#{encodeURIComponent "https://zion.angry.im"}"
  # Scalar token for Scalar
  if scalarToken?
    url += "&scalar_token=#{encodeURIComponent scalarToken}"
  return url.replace /%24/g, '$'

DEFAULT_IM_API_URL = 'https://scalar.vector.im/api'
DEFAULT_IM_UI_URL = 'https://scalar.vector.im/'

IM_KIND_DEFAULT = 0
IM_KIND_HS = 1

export IntegrationManagerManagerContext = React.createContext null

# Based on classes in matrix-react-sdk
export class IntegrationManagerManager
  constructor: (@client) ->
    @managers = []
    @managers.push new IntegrationManager @client, IM_KIND_DEFAULT, DEFAULT_IM_API_URL, DEFAULT_IM_UI_URL

  # TODO: should we support multiple IMs?
  #       maybe only after we actually have full IM support.
  getMainManager: ->
    if @managers.length == 0
      null
    else
      @managers[@managers.length - 1]

  # If testUrl is a valid scalar url under some known integration
  # manager, return the integration manager instance
  # otherwise, returns null
  isScalarUrl: (testUrl) ->
    for m in @managers
      return m if m.isScalarUrl testUrl
    return null

  startListening: ->
    @client.on 'WellKnown.client', @onWellKnownInfo

  stopListening: ->
    @client.removeListener 'WellKnown.client', @onWellKnownInfo

  onWellKnownInfo: (ev) =>
    return unless ev? and ev['m.integrations']?
    managers = ev['m.integrations']['managers']
    return unless managers? and Array.isArray managers

    @managers = @managers.filter (m) -> m.kind isnt IM_KIND_HS

    for m in managers
      continue unless m['api_url']
      @managers.push new IntegrationManager @client, IM_KIND_HS,
        m['api_url'], m['ui_url']

export class IntegrationManager
  constructor: (@client, @kind, @apiUrl, @uiUrl) ->
    @apiUrlParsed = new URL @apiUrl
    @scalarToken = null

  # Return true if the given url is a valid
  # Scalar url under the current IM
  isScalarUrl: (testUrl) ->
    testUrlParsed = new URL testUrl
    testUrlParsed.protocol is @apiUrlParsed.protocol and
      testUrlParsed.host is @apiUrlParsed.host and
      testUrlParsed.pathname.startsWith @apiUrlParsed.pathname

  # Connects to Scalar API and fetches the scalar token
  getScalarToken: ->
    if @scalarToken?
      return @scalarToken
    token = await AsyncStorage.getItem "@im_scalar_token_#{@apiUrl}"
    unless token?
      openIDToken = await @client.getOpenIdToken()
      token = await @exchangeForScalarToken openIDToken
    # TODO: check the validity of the token, and
    #       support the Terms page
    if token?
      await AsyncStorage.setItem "@im_scalar_token_#{@apiUrl}", token
    token
    
  exchangeForScalarToken: (openIDToken) ->
    res = await fetch "#{@apiUrl}/register?v=1.1",
      method: 'POST'
      headers:
        'Content-Type': 'application/json'
      body: JSON.stringify openIDToken
    data = await res.json()
    data.scalar_token