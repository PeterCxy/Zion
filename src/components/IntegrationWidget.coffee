import React, { useCallback, useContext, useEffect, useState, useRef } from "react"
import { WebView } from "react-native-webview"
import { MatrixClientContext } from "../util/client"
import * as integrations from "../util/integrations"
import * as util from "../util/util"

WIDGET_API_VERSIONS = [
  "0.0.1", # Basic
  "0.0.2", # OpenID support
]

# TODO: implement more Scalar APIs
export default IntegrationWidget = ({widget, onSendSticker}) ->
  client = useContext MatrixClientContext
  imm = useContext integrations.IntegrationManagerManagerContext
  webviewRef = useRef null
  reqIdPromiseMap = useRef {}
  [widgetURL, setWidgetURL] = useState -> 
    integrations.getWidgetURL widget

  # Fetch scalar_token if needed for legacy IMs
  useEffect ->
    im = imm.isScalarUrl widget.content.url
    unless im?
      console.log "Refusing to add scalar_token because no matching IM found"
      return

    do ->
      try
        token = await im.getScalarToken()
        return unless token?
        setWidgetURL integrations.getWidgetURL widget, token
      catch err
        console.log err
    
    return
  , [widget]

  sendMessageToWebview = useCallback (msg) ->
    webviewRef.current.injectJavaScript """
      (function() {
        window.dispatchEvent(new MessageEvent('message', { data: #{JSON.stringify msg}}));
      })();
    """
  , []

  requestWidget = useCallback (action, reqId, data) ->
    reqId = reqId ? util.randomId 10
    new Promise (resolve, reject) ->
      resolved = false
      # The promise will be resolved in onMessage
      # or rejected when it times out
      reqIdPromiseMap.current[reqId] =
        resolve: (res) ->
          resolved = true
          resolve res
        reject: reject
      req = 
        api: 'toWidget'
        action: action
        requestId: reqId
      req.data = data if data?
      sendMessageToWebview req
      setTimeout ->
        if not resolved
          reject 'request timeout'
          reqIdPromiseMap.current[reqId] = null
      , 1000
  , []

  loadOpenIDCredentials = useCallback (reqId) ->
    # TODO: should we ask the user for confirmation?
    try
      token = await client.getOpenIdToken()
      await requestWidget 'openid_credentials', reqId, Object.assign { success: true }, token
    catch err
      await requestWidget 'openid_credentials', reqId, { success: false }
  , [client]
  
  handleRequestFromWidget = useCallback (req) ->
    respond = (resp) ->
      sendMessageToWebview
        api: 'fromWidget'
        requestId: req.requestId
        action: req.action
        response: resp

    switch req.action
      when 'supported_api_versions'
        respond
          api: 'fromWidget'
          supported_versions: WIDGET_API_VERSIONS
      when 'get_openid'
        respond
          state: 'request'
        loadOpenIDCredentials()
      when 'm.sticker'
        onSendSticker req.data if onSendSticker?
      else
        console.log "Unknown fromWidget API: #{req.action}"
        console.log req
  , [loadOpenIDCredentials]

  onLoadStart = useCallback ->
    console.log "onLoadStart"
    webviewRef.current.injectJavaScript """
      (function() {
        window.opener = {};
        postMessage = function(data) {
          window.ReactNativeWebView.postMessage(JSON.stringify(data));
        };
        window.opener.postMessage = postMessage;
        window.postMessage = postMessage;
      })();
    """
    #webviewRef.current.injectJavaScript "console.log = function (msg) { window.ReactNativeWebView.postMessage(msg); };"
  , []

  onLoad = useCallback ->
    try
      console.log "Sending capabilities request to widget"
      {capabilities} = await requestWidget 'capabilities'
      console.log "widget capabilities:"
      console.log capabilities # TODO: what should we do with these?
    catch err
      console.log err
  , []

  onMessage = useCallback (msg) ->
    #console.log msg
    data = JSON.parse msg.nativeEvent.data
    console.log data

    if data.api is 'toWidget'
      if reqIdPromiseMap.current[data.requestId]?
        reqIdPromiseMap.current[data.requestId].resolve data.response
        reqIdPromiseMap.current[data.requestId] = null
    else if data.api is 'fromWidget'
      handleRequestFromWidget data
  , [handleRequestFromWidget]

  <WebView
    ref={webviewRef}
    source={{ uri: widgetURL }}
    cacheEnabled={true}
    domStorageEnabled={true}
    onLoadStart={onLoadStart}
    onLoad={onLoad}
    onMessage={onMessage}/>