import React, { useEffect, useRef, useState } from "react"
import { Animated, Image, Text, View } from "react-native"
import { useCachedFetch } from "../util/cache"
import { useStyles } from "../theme"

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
  [theme, styles] = useStyles buildStyles
  fadeAnim = useRef(new Animated.Value 1).current
  [dataURL, _] = useCachedFetch url, (dUrl, callback) ->
    # Play animation first
    Animated.timing fadeAnim,
      toValue: 0
      duration: 200
      useNativeDriver: true
    .start ->
      callback()
      Animated.timing fadeAnim,
        toValue: 1
        duration: 200
        useNativeDriver: true
      .start()

  if not dataURL
    <Animated.View style={Object.assign {}, styles.styleTextBackground, style, { opacity: fadeAnim }}>
      <Text style={styles.styleText}>{extractCapitals name}</Text>
    </Animated.View>
  else
    <Animated.Image style={Object.assign {}, style, { opacity: fadeAnim }} source={{ uri: dataURL }}/>

buildStyles = (theme) ->
    styleTextBackground:
      alignItems: "center"
      justifyContent: "center"
      backgroundColor: theme.COLOR_PRIMARY
    styleText:
      color: theme.COLOR_TEXT_PRIMARY