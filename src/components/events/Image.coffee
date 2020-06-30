import React, { useContext, useMemo } from "react"
import { Text, View, useWindowDimensions } from "react-native"
import ImageThumbnail from "../ImageThumbnail"
import { MatrixClientContext } from "../../util/client"
import { translate } from "../../util/i18n"
import { useStyles } from "../../theme"

export default Image = ({ev}) ->
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles
  windowWidth = useWindowDimensions().width
  windowHeight = useWindowDimensions().height
  windowScale = useWindowDimensions().scale

  [width, height] = useMemo ->
    w = ev.info.thumbnail.width / windowScale
    if w > windowWidth * 0.6
      w = 0.6 * windowWidth
    if w < 50 * windowScale
      w = 50 * windowScale
    h = ev.info.thumbnail.height / ev.info.thumbnail.width * w
    if h > windowHeight * 0.9
      h = windowHeight * 0.9
    if h < 20 * windowScale
      h = 20 * windowScale
      w = ev.info.thumbnail.width / ev.info.thumbnail.height * h
      if w > windowWidth * 0.6
        w = windowWidth * 0.6
    [w, h]
  , [ windowWidth, windowScale ]

  httpUrl = useMemo ->
    if ev.info.thumbnail.url
      client.mxcUrlToHttp ev.info.thumbnail.url,
        width * windowScale, height * windowScale, "scale"
    else
      null
  , [width, height, windowScale]

  date = useMemo ->
    new Date ev.ts
  , [ev.ts]

  <View
    style={styles.styleWrapperWrapper}>
    <View
      style={styles.styleWrapper}>
      <ImageThumbnail
        url={httpUrl}
        width={width}
        height={height}/>
      <View
        style={Object.assign {}, styles.styleTextWrapper, { maxWidth: width * 0.8 }}>
        <Text style={styles.styleText}>{
          translate "time_format_hour_minute",
            ('' + date.getHours()).padStart(2, '0'),
            ('' + date.getMinutes()).padStart(2, '0')}
        </Text>
      </View>
    </View>
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