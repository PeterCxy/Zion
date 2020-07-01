import React, { useContext, useEffect, useState } from "react"
import { Easing, Image, View } from "react-native"
import { ProgressBar } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import ImageViewer from "react-native-image-zoom-viewer"
import { MatrixClientContext } from "../util/client"
import * as cache from "../util/cache"
import * as util from "../util/util"
import { useStyles } from "../theme"

export default ImageViewerScreen = ({route}) ->
  # We take both the thumbnail url and the actual thumbnail data
  # because the thumbnail may not fit in memory cache
  # but we want a smooth transition.
  # Refer to RoomTimeline for the content of "info"
  # (the "info" field of a transformed m.image message)
  {thumbnailUrl, thumbnailDataUrl, info} = route.params
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles
  [loading, setLoading] = useState true
  [dataUrl, setDataUrl] = useState thumbnailDataUrl
  [progress, setProgress] = useState -1

  largeUrl = client.mxcUrlToHttp info.url ? info.cryptoInfo.url
  [largeDataUrl, _] = cache.useCachedFetch largeUrl, info.mime,
    info.cryptoInfo, (_, callback) ->
      callback()
    , (progress) ->
      setProgress progress

  useEffect ->
    return if not largeDataUrl?

    util.asyncRunAfterInteractions ->
      setDataUrl largeDataUrl
      setLoading false

    return
  , [largeDataUrl?]

  <ImageViewer
    imageUrls={[{ url: dataUrl }]}
    saveToLocalByLongPress={false} # TODO: too ugly. implement this ourselves.
    renderHeader={->
      <ProgressBar
        style={styles.styleProgress}
        indeterminate={progress == -1}
        progress={progress}
        color={theme.COLOR_ACCENT}
        visible={loading}/>
    }
    renderImage={(props) ->
      # TODO: handle multiple images (how to set the IDs?)
      <SharedElement id={"image.thumbnail.#{thumbnailUrl}"}>
        <Image {...props}/>
      </SharedElement>
    }/>

ImageViewerScreen.sharedElements = (route, otherRoute, showing) ->
  # Only use the animation when coming FROM the Chat UI
  if otherRoute.name == "Chat" and showing
    ["image.thumbnail.#{route.params.thumbnailUrl}"]

ImageViewerScreen.navigationOptions =
  transitionSpec:
    open:
      animation: 'timing'
      config:
        duration: 500
        easing: Easing.out Easing.ease
    close:
      animation: 'timing'
      config:
        duration: 500
        easing: Easing.in Easing.ease
  cardStyleInterpolator: ({ current, closing }) ->
    cardStyle:
      opacity: current.progress

buildStyles = (theme) ->
    styleProgress:
      width: '100%'
      height: 2
      backgroundColor: 'rgb(0, 0, 0)'