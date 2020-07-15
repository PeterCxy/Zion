import React, { useCallback, useContext, useEffect, useMemo, useState } from "react"
import { Text, TouchableWithoutFeedback, View } from "react-native"
import { ActivityIndicator } from "react-native-paper"
import Icon from "react-native-vector-icons/MaterialCommunityIcons"
import filesize from "filesize"
import { useStyles } from "../../theme"
import { MatrixClientContext } from "../../util/client"
import * as cache from "../../util/cache"
import NativeUtils from "../../util/NativeUtils"

STATE_INITIAL = 0
STATE_DOWNLOADING = 1
STATE_DOWNLOADED = 2

FILE_SIZE_OPTIONS =
  base: 2
  locale: true
  round: 2

# Note: we do NOT expect the content of ev.info to change
#       during the lifetime of this component.
export default Attachment = ({ev, onExtraInfoChange}) ->
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles
  [state, setState] = useState STATE_INITIAL
  [downloadedSizeStr, setDownloadedSizeStr] = useState null
  [downloadedPath, setDownloadedPath] = useState null
  [downloadedMime, setDownloadedMime] = useState null

  styles = if ev.self then styles.reverse else styles
  iconColor = if ev.self then theme.COLOR_TEXT_PRIMARY else theme.COLOR_TEXT_ON_BACKGROUND

  url = useMemo ->
    client.mxcUrlToHttp ev.info.url ? ev.info.cryptoInfo.url
  , []

  handleDownloadedFile = useCallback (mime, path) ->
    setDownloadedMime mime
    setDownloadedPath path
    setState STATE_DOWNLOADED
    # For use in Chat.coffee to determine whether to show the save icon
    onExtraInfoChange
      savable: true
      save: ->
        NativeUtils.saveFileToExternal path, ev.info.title, mime
  , []

  handleFetchPromise = useCallback (promise) ->
    try
      [mime, path] = await promise
      console.log "Downloaded #{mime} to #{path}"
      handleDownloadedFile mime, path
    catch err
      console.log err
      setState STATE_INITIAL
  , []

  handleProgress = useCallback (progress) ->
    downloadedSize = progress * ev.info.size
    setDownloadedSizeStr filesize downloadedSize, FILE_SIZE_OPTIONS
  , []

  # Check if the file has already been downloaded before
  # or is being downloaded right now
  useEffect ->
    do ->
      try
        [mime, path] = await cache.checkCache url
        handleDownloadedFile mime, path
        return
      catch err
        # When there is no cache, the above operation will fail
        # because checkCache returns null, which cannot be
        # destructed

      # If no local file found, check if there is ongoing download
      promise = await cache.checkOngoingFetch url, handleProgress
      return unless promise?
      setState STATE_DOWNLOADING
      
      # Wait for download to finish just as we always do
      handleFetchPromise promise.promise

    return
  , []

  # Start downloading when the state is first set to downloading
  # Nothing else can change the state in STATE_DOWNLOADING
  useEffect ->
    return unless state is STATE_DOWNLOADING

    do ->
      handleFetchPromise cache.cachedFetch url,
          ev.info.mime, ev.info.cryptoInfo, handleProgress

    return
  , [state]

  readableSize = useMemo ->
    filesize ev.info.size, FILE_SIZE_OPTIONS
  , []

  onIconPress = useCallback ->
    switch state
      when STATE_INITIAL
        setState STATE_DOWNLOADING
      when STATE_DOWNLOADED
        NativeUtils.openFile downloadedPath
  , [state, downloadedPath]

  <View style={styles.styleWrapper}>
    <TouchableWithoutFeedback onPress={onIconPress}>
      <View style={styles.styleActionIconWrapper}>
        {
          switch state
            when STATE_INITIAL
              <Icon
                name="download"
                size={24}
                color={iconColor}/>
            when STATE_DOWNLOADING
              <ActivityIndicator
                animating={true}
                color={theme.COLOR_ACCENT}
                size={24}/>
            when STATE_DOWNLOADED
              <Icon
                name="file"
                size={24}
                color={iconColor}/>
        }
      </View>
    </TouchableWithoutFeedback>
    <View style={styles.styleInfoWrapper}>
      <Text style={styles.styleInfoTitle} numberOfLines={1}>
        {ev.info.title}
      </Text>
      <Text style={styles.styleInfoSize} numberOfLines={1}>
        {
          if state is STATE_DOWNLOADING and downloadedSizeStr?
            "#{downloadedSizeStr} / #{readableSize}"
          else
            readableSize
        }
      </Text>
    </View>
  </View>

buildStyles = (theme) ->
  styles =
    styleWrapper:
      flexDirection: 'row'
      alignItems: 'center'
      margin: 10
    styleActionIconWrapper:
      width: 48
      height: 48
      borderRadius: 24
      backgroundColor: 'rgba(0, 0, 0, .2)'
      alignItems: 'center'
      justifyContent: 'center'
    styleInfoWrapper:
      flexDirection: 'column'
      marginStart: 8
    styleInfoTitle:
      fontSize: 14
      color: theme.COLOR_TEXT_ON_BACKGROUND
    styleInfoTitleReverse:
      color: theme.COLOR_TEXT_PRIMARY
    styleInfoSize:
      fontSize: 14
      color: theme.COLOR_TEXT_SECONDARY_ON_BACKGROUND
    styleInfoSizeReverse:
      color: theme.COLOR_TEXT_PRIMARY
      opacity: 0.5

  styles.reverse = Object.assign {}, styles,
    styleInfoTitle: Object.assign {}, styles.styleInfoTitle, styles.styleInfoTitleReverse
    styleInfoSize: Object.assign {}, styles.styleInfoSize, styles.styleInfoSizeReverse

  styles