import React, { useContext, useEffect, useState } from "react"
import { Easing, Image, TouchableWithoutFeedback, View } from "react-native"
import { ProgressBar } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import ImageViewer from "react-native-image-zoom-viewer"
import { BottomSheet, BottomSheetItem } from "../components/BottomSheet"
import { MatrixClientContext } from "../util/client"
import * as cache from "../util/cache"
import * as util from "../util/util"
import { translate } from "../util/i18n"
import NativeUtils from "../util/NativeUtils"
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
  [showMenu, setShowMenu] = useState false

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

  <>
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
        <TouchableWithoutFeedback
          onLongPress={->
            util.performHapticFeedback()
            return if loading or not largeDataUrl?
            setShowMenu true
          }>
          <SharedElement id={"image.thumbnail.#{thumbnailUrl}"}>
            <Image {...props}/>
          </SharedElement>
        </TouchableWithoutFeedback>
      }/>
    <BottomSheet
      show={showMenu}
      title={translate "image_ops"}
      onClose={-> setShowMenu false}>
      <BottomSheetItem
        icon="download"
        title={translate "msg_ops_save"}
        onPress={->
          setShowMenu false
          [mime, path] = await cache.checkCache largeUrl
          try
            await NativeUtils.saveFileToExternal path, info.title, mime
          catch err
            console.log err
        }/>
      <BottomSheetItem
        icon="share"
        title={translate "msg_ops_share"}
        onPress={->
          setShowMenu false
          [mime, path] = await cache.checkCache largeUrl
          NativeUtils.shareFile path, info.title, mime, translate "msg_ops_share"
        }/>
    </BottomSheet>
  </>

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