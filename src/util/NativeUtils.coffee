import { NativeEventEmitter, NativeModules } from "react-native"

eventEmitter = new NativeEventEmitter NativeModules.NativeUtils

_uploadContentUri = NativeModules.NativeUtils.uploadContentUri
NativeModules.NativeUtils.uploadContentUri = (client, uri, progressCallback) ->
  progressListener = (ev) ->
    if progressCallback?
      progressCallback ev.uploaded, ev.total
  eventEmitter.addListener "onProgress_#{uri}", progressListener
  try
    return await _uploadContentUri client.getHomeserverUrl(), client.getAccessToken(), uri
  catch e
    throw e
  finally
    eventEmitter.removeListener "onProgress_#{uri}", progressListener

export default NativeModules.NativeUtils