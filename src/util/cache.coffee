import React, { useEffect, useState } from "react"
import { LRUMap } from 'lru_map'
import RNFetchBlob from 'rn-fetch-blob'
import * as RNFS from 'react-native-fs'
import { sha1 } from 'react-native-sha1'
import AsyncFileOps from './AsyncFileOps'
import * as EncryptedAttachment from './EncryptedAttachment'

# A cached fetch using in-memory LRU + FS cache
# and the fetched content will be data URLs
# This should only be used for avatars / thumbnails
memCache = new LRUMap 128

MEM_CACHE_MAX_FILE_SIZE = 100 * 1024 # 100kB

# FS cache path
FS_CACHE_PATH = "#{RNFS.DocumentDirectoryPath}/cache"
FS_TEMP_PATH = "#{RNFS.DocumentDirectoryPath}/temp"

fsCachePath = (url) ->
  "#{FS_CACHE_PATH}/#{await sha1 url}"

fsTempPath = (url) ->
  "#{FS_TEMP_PATH}/#{await sha1 url}"

# Fetch only from memory cache
export fetchMemCache = (url) ->
  if url and memCache.has url
    memCache.get url
  else
    null

# Fetch as data URL
# Also supports decrypting encrypted remote data
# via "EncryptedAttachment" native module
# When decryption is needed, mime and cryptoInfo must
# not be null
export cachedFetchAsDataURL = (url, mime, cryptoInfo, onProgress) ->
  (await CachedDownload.getInstance url, mime, cryptoInfo)
    .registerProgressListener onProgress
    .fetch()

# Handles deduplication of requests
# so that we don't fire a lot of requests for the
# same resource simutaneously when multiple are
# shown at the same time on screen (e.g. avatars in room timeline)
class CachedDownload
  @instances: {}

  @calculateInstanceHash: (url, mime, cryptoInfo) ->
    await sha1 JSON.stringify
      url: url
      mime: mime
      cryptoInfo: cryptoInfo

  @getInstance: (url, mime, cryptoInfo) ->
    hash = await @calculateInstanceHash url, mime, cryptoInfo
    if not @instances[hash]
      @instances[hash] = new CachedDownload url, mime, cryptoInfo
    @instances[hash]

  constructor: (@url, @mime, @cryptoInfo) ->
    @promise = null
    @progressListeners = []

  registerProgressListener: (listener) =>
    if listener?
      @progressListeners.push listener
    @

  deleteSelf: =>
    # Delete ourselves from the instance list
    hash = await CachedDownload.calculateInstanceHash @url, @mime, @cryptoInfo
    delete CachedDownload.instances[hash]

  fetch: =>
    # Ensure we only ever have one request promise for each resource
    # This function returns the same promise for simultaneous requests
    # for the same resource
    if not @promise?
      # If there is no request ongoing, make a new one
      # Note that we do not await the promise here.
      # Instead, we just store the promise and return it
      # So that when we are working to fetch things,
      # new requests won't be made for the same resource
      @promise = do =>
        try
          res = await @_doFetch()
          return res
        finally
          await @deleteSelf()
    @promise

  _doFetch: =>
    # Check the memory cache first
    if memCache.has @url
      return Promise.resolve memCache.get @url
    # Ensure FS dir exists
    await RNFS.mkdir FS_CACHE_PATH
    await RNFS.mkdir FS_TEMP_PATH
    # Then check fs cache
    fsPath = await fsCachePath @url
    if await RNFS.exists fsPath
      dUrl = await AsyncFileOps.readAsString fsPath
      if dUrl.length < MEM_CACHE_MAX_FILE_SIZE
        # Also set memory cache
        memCache.set @url, dUrl
      return dUrl

    # No cache found, fetch
    tmpPath = await fsTempPath @url
    resp = await RNFetchBlob.config
      fileCache: true
      path: tmpPath
    .fetch 'GET', @url
    .progress (received, total) =>
      p = received / total
      @progressListeners.forEach (listener) =>
        listener p
    info = resp.info()
    if info.status != 200
      resp.flush()
      return null
    mimeType = @mime ? info.headers["content-type"].split(";")[0].trim()
    # Handle decryption here
    if @cryptoInfo?
      data = await EncryptedAttachment.decryptAttachmentToBase64 tmpPath, @cryptoInfo
    else
      data = await AsyncFileOps.readAsBase64 tmpPath

    dUrl = "data:" + mimeType + ";base64," + data
    resp.flush()

    # Write to both mem and fs cache
    if dUrl.length < MEM_CACHE_MAX_FILE_SIZE
      memCache.set @url, dUrl
    await AsyncFileOps.writeString await fsCachePath(@url), dUrl

    return dUrl

# A React hook for using cached dataURL
# When decryption is needed, mime and cryptoInfo must not be null
export useCachedFetch = (url, mime, cryptoInfo, onFetched, onProgress) ->
  [dataURL, setDataURL] = useState fetchMemCache url
  [immediatelyAvailable, setImmediatelyAvailable] = useState false

  useEffect ->
    if dataURL and url
      setImmediatelyAvailable true
    return if dataURL or not url

    unmounted = false
    do ->
      try
        dUrl = await cachedFetchAsDataURL url, mime, cryptoInfo, onProgress
      catch err
        console.warn err
        return

      if dUrl and not unmounted
        onFetched dUrl, ->
          return if unmounted
          setDataURL dUrl

    return ->
      unmounted = true
  , []

  [dataURL, immediatelyAvailable]