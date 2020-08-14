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

_uploadContentThumbnail = NativeModules.NativeUtils.uploadContentThumbnail
NativeModules.NativeUtils.uploadContentThumbnail = (client, uri, size) ->
  _uploadContentThumbnail client.getHomeserverUrl(), client.getAccessToken(), uri, size

export default NativeModules.NativeUtils