import React from "react"
import { View } from "react-native"
import EventDayDivider from "./EventDayDivider"
import EventWithAvatar from "./EventWithAvatar"
import RoomState from "./RoomState"
import UnknownEvent from "./UnknownEvent"
import { useStyles } from "../../theme"

# Dispatcher of event rendering in room timeline
# Every concrete types of events will be implemented by a sub-component
export default Event = ({ev}) ->
  [theme, styles] = useStyles buildStyles

  wrapperStyle = if ev.self
    styles.styleLineWrapperReverse
  else
    styles.styleLineWrapper
  if not ev.sent
    wrapperStyle = Object.assign {}, wrapperStyle, { opacity: 0.5 }

  <>
    <EventDayDivider ev={ev}/>
    <View
      style={wrapperStyle}>
      {
        switch ev.type
          when 'msg_text', 'msg_html', 'msg_sticker', 'msg_image'
            <EventWithAvatar ev={ev}/>
          when 'room_state'
            <RoomState ev={ev}/>
          else
            <UnknownEvent ev={ev}/>
      }
    </View>
  </>

buildStyles = (theme) ->
  ret =
    styleLineWrapper:
      alignSelf: "stretch"
      flexDirection: "row"
      padding: 10
    styleLineWrapperReverse:
      flexDirection: "row-reverse"

  ret.styleLineWrapperReverse =
    Object.assign {}, ret.styleLineWrapper, ret.styleLineWrapperReverse

  ret