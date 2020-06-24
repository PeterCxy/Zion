import React, { useContext, useMemo } from "react"

export default ThemeContext = React.createContext null

export useStyles = (buildStyles) ->
  {theme} = useContext ThemeContext
  styles = useMemo ->
    buildStyles theme
  , [theme]
  [theme, styles]