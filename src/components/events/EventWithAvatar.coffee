import React from "react"
import { TouchableWithoutFeedback, View } from "react-native"
import Avatar from "../Avatar"
import TextMsg from "./TextMsg"
import Sticker from "./Sticker"
import Image from "./Image"
import { useStyles } from "../../theme"
import { performHapticFeedback } from "../../util/util"

# An event that needs to show an avatar (normal-sized)
export default EventWithAvatar = ({ev, onMessageSelected}) ->
  [theme, styles] = useStyles buildStyles

  <>
    <Avatar
      style={if ev.self then styles.styleMsgAvatarReverse else styles.styleMsgAvatar}
      name={ev.sender.name}
      url={ev.sender.avatar}/>
    <TouchableWithoutFeedback
      onLongPress={->
        performHapticFeedback()
        onMessageSelected ev if onMessageSelected?
      }>
      <View>
      {
        switch ev.type
          when 'msg_text', 'msg_html'
            <TextMsg ev={ev}/>
          when 'msg_sticker'
            <Sticker ev={ev}/>
          when 'msg_image'
            <Image ev={ev}/>
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

  ret.styleMsgAvatarReverse =
    Object.assign {}, ret.styleMsgAvatar, ret.styleMsgAvatarReverse

  ret