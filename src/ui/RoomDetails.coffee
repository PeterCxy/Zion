import React, { useContext, useEffect, useState } from "react"
import { Text, View, useWindowDimensions } from "react-native"
import { Appbar } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import { EventTimeline } from "matrix-js-sdk"
import Avatar from "../components/Avatar"
import CollapsingHeaderView from "../components/CollapsingHeaderView"
import PreferenceCategory from "../components/preferences/PreferenceCategory"
import Preference from "../components/preferences/Preference"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"
import * as mext from "../util/matrix"
import { DEFAULT_APPBAR_HEIGHT } from "../util/util"

HEADER_SIZE = 300

export default RoomDetails = ({route, navigation}) ->
  {roomId, avatarPlaceholder} = route.params
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles
  windowHeight = useWindowDimensions().height

  # Note: this is not a page where we expect users to spend a long time on
  # so we do not implement any state update events for this page
  [name, setName] = useState -> client.getRoom(roomId).name
  [avatar, setAvatar] = useState ->
    mext.calculateRoomHugeAvatarURL client, client.getRoom roomId
  [firstAlias, setFirstAlias] = useState ->
    client.getRoom(roomId).getCanonicalAlias() ? roomId
  [desc, setDesc] = useState ->
    client.getRoom(roomId).getLiveTimeline()
      .getState(EventTimeline.FORWARDS)
      .getStateEvents("m.room.topic", "")
      ?.getContent().topic ? translate "room_details_description_default"
  [isEncrypted, setIsEncrypted] = useState -> client.isRoomEncrypted roomId
  [hasUntrustedDevice, setHasUntrustedDevice] = useState false

  useEffect ->
    unmounted = false

    do ->
      res = await client.getRoom(roomId).hasUnverifiedDevices()
      setHasUntrustedDevice res unless unmounted

    return ->
      unmounted = true
  , []

  <CollapsingHeaderView
    headerHeight={HEADER_SIZE}
    headerBackground={theme.COLOR_PRIMARY}
    goBack={-> navigation.goBack()}
    renderAppbar={->
      <Appbar.Header style={{ elevation: 0 }}>
        <Appbar.BackAction
          onPress={-> navigation.goBack()}/>
        <Appbar.Content
          title={name}/>
      </Appbar.Header>
    }
    renderHeader={->
      <View style={styles.styleHeaderWrapper}>
        <SharedElement id={"room.#{roomId}.avatar"}>
          <Avatar
            style={styles.styleAvatar}
            placeholder={avatarPlaceholder}
            url={avatar}
            name={name}/>
        </SharedElement>
        <Text style={styles.styleHeaderNameText}>{name}</Text>
        <Text style={styles.styleHeaderAliasText}>{firstAlias}</Text>
      </View>
    }>
    <View style={{ minHeight: windowHeight - DEFAULT_APPBAR_HEIGHT }}>
      <PreferenceCategory
        title={translate "room_details_overview"}>
        <Preference
          icon="information"
          title={translate "room_details_description"}
          summary={desc}/>
        <Preference
          icon="lock"
          title={translate "room_details_encryption"}
          summary={
            if isEncrypted and not hasUntrustedDevice
              translate "room_details_encryption_enabled"
            else if hasUntrustedDevice
              translate "room_details_encryption_untrusted"
            else
              translate "room_details_encryption_disabled"
          }/>
      </PreferenceCategory>
    </View>
  </CollapsingHeaderView>

RoomDetails.sharedElements = (route, otherRoute, showing) ->
  if otherRoute.name == "Chat"
    ["room.#{route.params.roomId}.avatar"]

buildStyles = (theme) ->
    styleHeaderWrapper:
      flex: 1
      alignSelf: "stretch"
      alignItems: "center"
      justifyContent: "center"
      flexDirection: "column"
      padding: 30
    styleAvatar:
      width: 128
      height: 128
      borderRadius: 64
      borderWidth: 1
      borderColor: theme.COLOR_SECONDARY
    styleHeaderNameText:
      color: theme.COLOR_TEXT_PRIMARY
      fontSize: 15
      fontWeight: "bold"
      marginTop: 20
      textAlign: "center"
    styleHeaderAliasText:
      color: theme.COLOR_TEXT_PRIMARY
      opacity: 0.8
      fontSize: 13
      marginTop: 5
      textAlign: "center"