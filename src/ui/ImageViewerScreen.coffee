import React, { useContext, useEffect, useState } from "react"
import { Image, View } from "react-native"
import { ProgressBar } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import ImageViewer from "react-native-image-zoom-viewer"
import { MatrixClientContext } from "../util/client"
import * as cache from "../util/cache"
import * as util from "../util/util"
import { useStyles } from "../theme"

export default ImageViewerScreen = ({route}) ->
  {thumbnailUrl, info} = route.params
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles
  [loading, setLoading] = useState true
  [dataUrl, setDataUrl] = useState cache.fetchMemCache thumbnailUrl

  largeUrl = client.mxcUrlToHttp info.url ? info.cryptoInfo.url
  [largeDataUrl, setLargeDataUrl] = cache.useCachedFetch largeUrl, info.mime,
    info.cryptoInfo, (_, callback) -> callback()

  useEffect ->
    return if not largeDataUrl?

    util.asyncRunAfterInteractions ->
      setDataUrl largeDataUrl
      setLoading false

    return
  , [largeDataUrl]

  <ImageViewer
    imageUrls={[{ url: dataUrl }]}
    renderHeader={->
      <ProgressBar
        style={styles.styleProgress}
        indeterminate={true}
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

buildStyles = (theme) ->
    styleProgress:
      width: '100%'
      height: 2
      backgroundColor: 'rgb(0, 0, 0)'