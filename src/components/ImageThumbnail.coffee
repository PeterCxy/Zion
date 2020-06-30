import React, { useRef, useMemo } from "react"
import { Animated, Image, View } from "react-native"
import { useCachedFetch } from "../util/cache"

export default ImageThumbnail = ({url, width, height, mime, cryptoInfo}) ->
  # Build cached styles
  styles = useMemo ->
      width: width
      height: height
  , [width, height]
  # We show nothing when we start
  fadeAnim = useRef(new Animated.Value 0).current
  # Lazy fetch
  [dataURL, immediatelyAvailable] = useCachedFetch url, mime, cryptoInfo, (dUrl, callback) ->
    callback()
    Animated.timing fadeAnim,
      toValue: 1
      duration: 200
      useNativeDriver: true
    .start()

  animatedStyles = if not immediatelyAvailable
    Object.assign {}, styles, { opacity: fadeAnim }
  else
    Object.assign {}, styles, { opacity: 1 }

  if not dataURL
    <Animated.View style={animatedStyles}/>
  else
    <Animated.Image style={animatedStyles} source={{ uri: dataURL }}/>