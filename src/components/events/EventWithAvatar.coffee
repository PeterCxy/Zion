import React from "react"
import { TouchableWithoutFeedback, View } from "react-native"
import Avatar from "../Avatar"
import EventWithBubble from "./EventWithBubble"
import Sticker from "./Sticker"
import { useStyles } from "../../theme"
import { performHapticFeedback } from "../../util/util"

# An event that needs to show an avatar (normal-sized)
export default EventWithAvatar = ({ev, onMessageSelected}) ->
  [theme, styles] = useStyles buildStyles

  styles = if ev.self then styles.reverse else styles

  <>
    <Avatar
      style={styles.styleMsgAvatar}
      name={ev.sender.name}
      url={ev.sender.avatar}/>
    <TouchableWithoutFeedback
      onLongPress={->
        performHapticFeedback()
        onMessageSelected ev if onMessageSelected? and not ev.unknown # "unknown" = not decrypted yet
      }>
      <View style={styles.styleChildWrapper}>
      {
        switch ev.type
          when 'msg_text', 'msg_html', 'msg_image'
            <EventWithBubble ev={ev}/>
          when 'msg_sticker'
            <Sticker ev={ev}/>
      }
      </View>
    </TouchableWithoutFeedback>
  </>

buildStyles = (theme) ->
  ret =
    styleMsgAvatar:
      width: 32
      height: 32
      marginEnd: 10
      borderRadius: 16
    styleMsgAvatarReverse:
      marginStart: 10
      marginEnd: 0
    styleChildWrapper:
      flex: 1
      alignSelf: 'stretch'
      flexDirection: 'row'
    styleChildWrapperReverse:
      flexDirection: 'row-reverse'

  ret.reverse = Object.assign {}, ret,
    styleMsgAvatar: Object.assign {}, ret.styleMsgAvatar, ret.styleMsgAvatarReverse
    styleChildWrapper: Object.assign {}, ret.styleChildWrapper, ret.styleChildWrapperReverse

  ret