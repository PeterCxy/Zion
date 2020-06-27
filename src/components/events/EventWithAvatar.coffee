import React from "react"
import Avatar from "../Avatar"
import TextMsg from "./TextMsg"
import Sticker from "./Sticker"
import { useStyles } from "../../theme"

# An event that needs to show an avatar (normal-sized)
export default EventWithAvatar = ({ev}) ->
  [theme, styles] = useStyles buildStyles

  <>
    <Avatar
      style={if ev.self then styles.styleMsgAvatarReverse else styles.styleMsgAvatar}
      name={ev.sender.name}
      url={ev.sender.avatar}/>
    {
      switch ev.type
        when 'msg_text', 'msg_html'
          <TextMsg ev={ev}/>
        when 'msg_sticker'
          <Sticker ev={ev}/>
    }
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