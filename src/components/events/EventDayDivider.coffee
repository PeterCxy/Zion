import React from "react"
import { Text, View } from "react-native"
import * as util from "../../util/util"
import { useStyles } from "../../theme"

# A conditional divider between events across days
# This is to help identify dates when scrolling
# back in the timeline
export default EventDayDivider = ({ev}) ->
  [theme, styles] = useStyles buildStyles

  if ev.prev_ts? and (not util.tsSameDay ev.ts, ev.prev_ts)
    <View style={styles.styleWrapper}>
      <Text style={styles.styleText}>
        {
          new Date(ev.ts).toLocaleDateString undefined,
            weekday: 'short'
            year: 'numeric'
            month: 'short'
            day: 'numeric'
        }
      </Text>
    </View>
  else
    <></>

buildStyles = (theme) ->
    styleWrapper:
      alignSelf: "stretch"
      justifyContent: "center"
      flexDirection: "row"
      padding: 10
    styleText:
      color: theme.COLOR_CHAT_DAY_DIVIDER
      fontSize: 13