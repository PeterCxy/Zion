# Utilities for Integration Managers (IMs)
# Partially based on matrix-react-sdk/src/utils/WidgetUtils.js
# TODO: implement authentication API (passing scalar_token to IMs)

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
export getWidgetURL = (widget) ->
  url = widget.content.url + "?"
  url += "widgetId=#{encodeURIComponent widget.id}&"
  # Fake parent url
  url += "parentUrl=#{encodeURIComponent "https://zion.angry.im"}"
  return url.replace /%24/g, '$'