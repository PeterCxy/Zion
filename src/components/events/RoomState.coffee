import React from "react"
import { Text, View } from "react-native"
import Avatar from "../Avatar"
import { useStyles } from "../../theme"

# A RoomState event is an event that indicates a change
# in the room state. This can be membership events etc.
# For these events, we display a small avatar and small
# text.
export default RoomState = ({ev}) ->
  [theme, styles] = useStyles buildStyles

  <>
    <Avatar
      style={if ev.self then styles.styleAvatarReverse else styles.styleAvatar}
      name={ev.sender.name}
      url={ev.sender.tinyAvatar}/>
    <View
      style={styles.styleTextWrapper}>
      <Text style={if ev.self then styles.styleTextReverse else styles.styleText}>
        {ev.body}
      </Text>
    </View>
  </>

buildStyles = (theme) ->
  ret =
    styleAvatar:
      width: 24
      height: 24
      marginEnd: 10
      borderRadius: 16
    styleAvatarReverse:
      marginStart: 10
      marginEnd: 0
    styleTextWrapper:
      flex: 1 # Make it follow the padding rules of parent flex container
    styleText:
      alignSelf: 'flex-start'
      fontSize: 14
      color: theme.COLOR_CHAT_STATE_EVENT
    styleTextReverse:
      alignSelf: 'flex-end'

  ret.styleAvatarReverse =
    Object.assign {}, ret.styleAvatar, ret.styleAvatarReverse
  ret.styleTextReverse =
    Object.assign {}, ret.styleText, ret.styleTextReverse

  ret