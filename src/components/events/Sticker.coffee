import React, { useMemo } from "react"
import { PixelRatio, useWindowDimensions } from "react-native"
import ImageThumbnail from "../ImageThumbnail"

export default Sticker = ({ev}) ->
  windowWidth = useWindowDimensions().width
  windowScale = useWindowDimensions().scale

  [width, height] = useMemo ->
    w = 512 / windowScale # A sticker is always 512 px wide
    if w > windowWidth
      w = 0.6 * windowWidth
    h = ev.height / ev.width * w
    [w, h]
  , [ windowWidth, windowScale ]

  <ImageThumbnail
    url={ev.url}
    width={width}
    height={height}/>