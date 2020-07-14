import React from "react"
import { View } from "react-native"
import { useStyles } from "../../theme"
import Attachment from "./Attachment"
import Image from "./Image"
import TextMsg from "./TextMsg"

export default EventWithBubble = ({ev}) ->
  [theme, styles] = useStyles buildStyles

  styles = if ev.self then styles.reverse else styles
  bubbleStyle = if not ev.failed
    styles.styleMsgBubble
  else
    styles.styleMsgBubbleReverseFailed

  if ev.type == 'msg_html' and ev.body.indexOf('<li>') != -1
    # There is a weird bug about lists in react-native-render-html
    # that causes the view, when in auto width, wrapping at each character
    # for now, let's fix it by making the width constant
    bubbleStyle = Object.assign {}, bubbleStyle, { width: '80%' }

  <View style={styles.styleMsgBubbleWrapper}>
    <View
      style={bubbleStyle}>
      {
        switch ev.type
          when 'msg_text', 'msg_html'
            <TextMsg ev={ev}/>
          when 'msg_image'
            <Image ev={ev}/>
          when 'msg_attachment'
            <Attachment ev={ev}/>
      }
    </View>
  </View>

buildStyles = (theme) ->
  styles =
    styleMsgBubbleWrapper:
      # Make the wrapper width fill the rest of the flexbox
      # Without wrapper, the max width of the bubble is
      # relative to the entire list, not the rest of flex
      flex: 1
    styleMsgBubble:
      alignSelf: 'flex-start' # Wrap-Content
      backgroundColor: theme.COLOR_CHAT_BUBBLE
      maxWidth: '90%'
      borderRadius: 8
    styleMsgBubbleReverse:
      alignSelf: 'flex-end'
      backgroundColor: theme.COLOR_PRIMARY
    styleMsgBubbleReverseFailed:
      backgroundColor: theme.COLOR_CHAT_BUBBLE_FAILED

  styles.reverse = Object.assign {}, styles,
    styleMsgBubble: Object.assign {}, styles.styleMsgBubble, styles.styleMsgBubbleReverse
    # Failed is always reverse
    styleMsgBubbleReverseFailed: Object.assign {}, styles.styleMsgBubbleReverse, styles.styleMsgBubbleReverseFailed
  
  styles