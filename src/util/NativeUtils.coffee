import { NativeEventEmitter, NativeModules } from "react-native"

eventEmitter = new NativeEventEmitter NativeModules.NativeUtils

_uploadContentUri = NativeModules.NativeUtils.uploadContentUri
NativeModules.NativeUtils.uploadContentUri = (client, uri, encrypt, progressCallback) ->
  progressListener = (ev) ->
    if progressCallback?
      progressCallback ev.uploaded, ev.total
  eventEmitter.addListener "onProgress_#{uri}", progressListener
  try
    return await _uploadContentUri client.getHomeserverUrl(), client.getAccessToken(), uri, encrypt
  catch e
    throw e
  finally
    eventEmitter.removeListener "onProgress_#{uri}", progressListener

_uploadContentThumbnail = NativeModules.NativeUtils.uploadContentThumbnail
NativeModules.NativeUtils.uploadContentThumbnail = (client, uri, size, encrypt) ->
  _uploadContentThumbnail client.getHomeserverUrl(), client.getAccessToken(), uri, size, encrypt

export default NativeModules.NativeUtils