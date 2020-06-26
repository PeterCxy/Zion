import React from "react"
import { Text } from "react-native"
import { translate } from "../../util/i18n"

export default UnknownEvent = ({ev}) ->
  <Text>{translate "room_event_unknown", ev.ev_type}</Text>