import React, { useEffect, useState } from "react"
import { LRUMap } from 'lru_map'
import RNFetchBlob from 'rn-fetch-blob'
import * as RNFS from 'react-native-fs'
import { sha1 } from 'react-native-sha1'

# A cached fetch using in-memory LRU + FS cache
# and the fetched content will be data URLs
# This should only be used for avatars / thumbnails
memCache = new LRUMap 128

# FS cache path
FS_CACHE_PATH = "#{RNFS.DocumentDirectoryPath}/cache"

fsCachePath = (url) ->
  "#{FS_CACHE_PATH}/#{await sha1 url}"

# Fetch only from memory cache
export fetchMemCache = (url) ->
  if url and memCache.has url
    memCache.get url
  else
    null

# Fetch as data URL
export cachedFetchAsDataURL = (url) ->
  # Check the memory cache first
  if memCache.has url
    return Promise.resolve memCache.get url
  # Ensure FS dir exists
  await RNFS.mkdir FS_CACHE_PATH
  # Then check fs cache
  fsPath = await fsCachePath url
  if await RNFS.exists fsPath
    dUrl = await RNFS.readFile fsPath, "utf8"
    # Also set memory cache
    memCache.set url, dUrl
    return dUrl

  # No cache found, fetch
  resp = await RNFetchBlob.config
    fileCache: true
  .fetch 'GET', url
  info = resp.info()
  if info.status != 200
    resp.flush()
    return null
  dUrl = "data:" + info.headers["content-type"].split(";")[0].trim() + ";base64," + await resp.base64()
  resp.flush()

  # Write to both mem and fs cache
  memCache.set url, dUrl
  await RNFS.writeFile await fsCachePath(url), dUrl, 'utf8'

  return dUrl

# A React hook for using cached dataURL
export useCachedFetch = (url, onFetched) ->
  [dataURL, setDataURL] = useState fetchMemCache url
  [immediatelyAvailable, setImmediatelyAvailable] = useState false

  useEffect ->
    if dataURL and url
      setImmediatelyAvailable true
    return if dataURL or not url

    unmounted = false
    do ->
      dUrl = await cachedFetchAsDataURL url

      if dUrl and not unmounted
        onFetched dUrl, ->
          return if unmounted
          setDataURL dUrl

    return ->
      unmounted = true
  , []

  [dataURL, immediatelyAvailable]