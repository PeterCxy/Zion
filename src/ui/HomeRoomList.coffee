import React from "react"
import { View } from "react-native"
import { Appbar } from "react-native-paper"
import RoomList from "../components/RoomList"
import { translate } from "../util/i18n"

export default HomeRoomList = () ->
  <>
    <Appbar.Header>
      <Appbar.Content title={translate "app_name"} />
    </Appbar.Header>
    <RoomList/>
  </>
