import React, { useContext } from "react"
import { View } from "react-native"
import Icon from "react-native-vector-icons/MaterialCommunityIcons"
import ThemeContext from "../theme"

# We don't implement this in Avatar itself because it works poorly
# with shared elements. Using a wrapper the outer component can insert
# a shared element inside this wrapper.
export default AvatarBadgeWrapper = ({style, icon, color, children}) ->
  {theme} = useContext ThemeContext

  <View style={style}>
    {children}
    {
      if icon
        <>
          <Icon
            name={icon}
            size={style.width / 4 + 2}
            color={theme.COLOR_AVATAR_BADGE_OUTLINE_DEFAULT}
            style={{
              position: 'absolute',
              right: 0,
              bottom: 0,
            }}/>
          <Icon
            name={icon}
            size={style.width / 4}
            color={color ? theme.COLOR_AVATAR_BADGE_DEFAULT}
            style={{
              position: 'absolute',
              right: 1,
              bottom: 1,
            }}/>
        </>
    }
  </View>