import React, { useRef, useMemo } from "react"
import { Animated, Image, View } from "react-native"
import { useCachedFetch } from "../util/cache"

export default ImageThumbnail = ({url, width, height}) ->
  # Build cached styles
  styles = useMemo ->
      width: width
      height: height
  , [width, height]
  # We show nothing when we start
  fadeAnim = useRef(new Animated.Value 0).current
  # Lazy fetch
  dataURL = useCachedFetch url, (dUrl, callback) ->
    callback()
    Animated.timing fadeAnim,
      toValue: 1
      duration: 200
      useNativeDriver: true
    .start()
  animatedStyles = Object.assign {}, styles, { opacity: fadeAnim }

  if not dataURL
    <Animated.View style={animatedStyles}/>
  else
    <Animated.Image style={animatedStyles} source={{ uri: dataURL }}/>