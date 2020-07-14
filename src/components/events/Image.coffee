import React, { useContext, useMemo, useRef } from "react"
import { Text, View, useWindowDimensions } from "react-native"
import ImageThumbnail from "../ImageThumbnail"
import { MatrixClientContext } from "../../util/client"
import { translate } from "../../util/i18n"
import { useStyles } from "../../theme"
import * as util from "../../util/util"
import { useNavigation } from '@react-navigation/native'
import { TouchableRipple } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"

export default Image = ({ev}) ->
  client = useContext MatrixClientContext
  navigation = useNavigation()
  refDataUrl = useRef null # when thumbnail loaded, this will be set
  [theme, styles] = useStyles buildStyles
  windowScale = useWindowDimensions().scale
  [width, height] = util.useFitImageDimensions ev.info.thumbnail.width, ev.info.thumbnail.height

  httpUrl = useMemo ->
    if ev.info.thumbnail.url
      client.mxcUrlToHttp ev.info.thumbnail.url,
        width * windowScale, height * windowScale, "scale"
    else if ev.info.thumbnail.cryptoInfo
      client.mxcUrlToHttp ev.info.thumbnail.cryptoInfo.url
    else
      null
  , [width, height, windowScale]

  date = useMemo ->
    new Date ev.ts
  , [ev.ts]

  <View
    style={styles.styleWrapperWrapper}>
    <TouchableRipple
      onPress={=>
        if refDataUrl.current?
          # Only allow loading image viewer when the thumbnail is loaded
          # We pass the thumbnail data along with the original url
          # because the thumbnail may not fit in the memory cache
          # Since we already have the data, just pass it over directly
          # to make the transition smooth
          navigation.navigate "ImageViewerScreen",
            { thumbnailUrl: httpUrl, thumbnailDataUrl: refDataUrl.current, info: ev.info }}>
      <View
        style={styles.styleWrapper}>
        <SharedElement id={"image.thumbnail.#{httpUrl}"}>
          <ImageThumbnail
            url={httpUrl}
            width={width}
            height={height}
            mime={ev.mime}
            refDataUrl={refDataUrl}
            cryptoInfo={ev.info.thumbnail.cryptoInfo}/>
        </SharedElement>
        <View
          style={Object.assign {}, styles.styleTextWrapper, { maxWidth: width * 0.8 }}>
          <Text style={styles.styleText}>{
            translate "time_format_hour_minute",
              ('' + date.getHours()).padStart(2, '0'),
              ('' + date.getMinutes()).padStart(2, '0')}
          </Text>
        </View>
      </View>
    </TouchableRipple>
  </View>

buildStyles = (theme) ->
    styleWrapperWrapper:
      borderRadius: 8
      overflow: 'hidden'
      padding: 4
      backgroundColor: theme.COLOR_CHAT_BUBBLE
    styleWrapper:
      borderRadius: 6
      overflow: 'hidden'
      backgroundColor: theme.COLOR_CHAT_BUBBLE
    styleTextWrapper:
      position: 'absolute'
      right: 5
      bottom: 5
      borderRadius: 2
      padding: 4
      backgroundColor: theme.COLOR_CHAT_IMAGE_INFO
      justifyContent: 'center'
      alignItems: 'center'
    styleText:
      fontSize: 12
      textAlign: 'center'
      color: theme.COLOR_CHAT_IMAGE_INFO_TEXT