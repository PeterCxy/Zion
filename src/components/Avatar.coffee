import React, { useEffect, useRef, useState } from "react"
import { Animated, Image, Text, View } from "react-native"
import RNFetchBlob from 'rn-fetch-blob'
import * as theme from "../theme/default"

# A cache of URL vs fetched image (data URL)
memoryCache = {}

extractCapital = (word) ->
  word = word.trim()
  if word.length == 0
    return ""
  else
    return word.toUpperCase().charAt(0)

extractCapitals = (name) ->
  splitted = name.split ' '
  if splitted.length == 0
    ""
  else if splitted.length == 1
    extractCapital splitted[0]
  else
    extractCapital(splitted[0]) + extractCapital(splitted[1])

# A view used for showing avatars
# If the URL is not fetched or null, we show a placeholder
# Generated from the name
# Otherwise show the fetched image after it gets fully loaded
export default Avatar = ({name, url, style}) ->
  [dataURL, setDataURL] = useState memoryCache[url]
  fadeAnim = useRef(new Animated.Value 1).current

  useEffect ->
    return if dataURL or not url

    do -> 
      resp = await RNFetchBlob.config
        fileCache: true
      .fetch 'GET', url
      info = resp.info()
      if info.status == 200
        dUrl = "data:" + info.headers["content-type"] + ";base64," + await resp.base64()
        memoryCache[dUrl] = dUrl
        
        # Play animation first
        Animated.timing fadeAnim,
          toValue: 0
          duration: 200
          useNativeDriver: true
        .start ->
          setDataURL dUrl
          Animated.timing fadeAnim,
            toValue: 1
            duration: 200
            useNativeDriver: true
          .start()
    return
  , []

  if not dataURL
    <Animated.View style={Object.assign {}, styleTextBackground, style, { opacity: fadeAnim }}>
      <Text style={styleText}>{extractCapitals name}</Text>
    </Animated.View>
  else
    <Animated.Image style={Object.assign {}, style, { opacity: fadeAnim }} source={{ uri: dataURL }}/>

styleTextBackground =
  alignItems: "center"
  justifyContent: "center"
  backgroundColor: theme.COLOR_PRIMARY

styleText =
  color: theme.COLOR_TEXT_PRIMARY