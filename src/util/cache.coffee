import React, { useEffect, useState } from "react"
import { LRUMap } from 'lru_map'
import RNFetchBlob from 'rn-fetch-blob'
import * as RNFS from 'react-native-fs'
import { sha1 } from 'react-native-sha1'
import * as EncryptedAttachment from './EncryptedAttachment'

# A cached fetch using in-memory LRU + FS cache
# and the fetched content will be data URLs
# This should only be used for avatars / thumbnails
memCache = new LRUMap 128

MEM_CACHE_MAX_FILE_SIZE = 500 * 1024 # 500kB

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
export cachedFetchAsDataURL = (url, mime, cryptoInfo) ->
  # Check the memory cache first
  if memCache.has url
    return Promise.resolve memCache.get url
  # Ensure FS dir exists
  await RNFS.mkdir FS_CACHE_PATH
  await RNFS.mkdir FS_TEMP_PATH
  # Then check fs cache
  fsPath = await fsCachePath url
  if await RNFS.exists fsPath
    dUrl = await RNFS.readFile fsPath, "utf8"
    # Also set memory cache
    memCache.set url, dUrl
    return dUrl

  # No cache found, fetch
  tmpPath = await fsTempPath url
  resp = await RNFetchBlob.config
    fileCache: true
    path: tmpPath
  .fetch 'GET', url
  info = resp.info()
  if info.status != 200
    resp.flush()
    return null
  mimeType = mime ? info.headers["content-type"].split(";")[0].trim()
  # Handle decryption here
  if cryptoInfo?
    data = await EncryptedAttachment.decryptAttachmentToBase64 tmpPath, cryptoInfo
  else
    data = await resp.base64()

  dUrl = "data:" + mimeType + ";base64," + data
  resp.flush()

  # Write to both mem and fs cache
  if dUrl.length < MEM_CACHE_MAX_FILE_SIZE
    memCache.set url, dUrl
  await RNFS.writeFile await fsCachePath(url), dUrl, 'utf8'

  return dUrl

# A React hook for using cached dataURL
# When decryption is needed, mime and cryptoInfo must not be null
export useCachedFetch = (url, mime, cryptoInfo, onFetched) ->
  [dataURL, setDataURL] = useState fetchMemCache url
  [immediatelyAvailable, setImmediatelyAvailable] = useState false

  useEffect ->
    if dataURL and url
      setImmediatelyAvailable true
    return if dataURL or not url

    unmounted = false
    do ->
      try
        dUrl = await cachedFetchAsDataURL url, mime, cryptoInfo
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