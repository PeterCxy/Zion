import React, { useContext, useState } from "react"
import { Text, View } from "react-native"
import { Appbar } from "react-native-paper"
import { SharedElement } from "react-navigation-shared-element"
import Avatar from "../components/Avatar"
import CollapsingHeaderView from "../components/CollapsingHeaderView"
import { useStyles } from "../theme"
import { MatrixClientContext } from "../util/client"
import * as mext from "../util/matrix"

export default RoomDetails = ({route, navigation}) ->
  {roomId, avatarPlaceholder} = route.params
  client = useContext MatrixClientContext
  [theme, styles] = useStyles buildStyles

  # Note: this is not a page where we expect users to spend a long time on
  # so we do not implement any state update events for this page
  [name, setName] = useState -> client.getRoom(roomId).name
  [avatar, setAvatar] = useState ->
    mext.calculateRoomHugeAvatarURL client, client.getRoom roomId
  [firstAlias, setFirstAlias] = useState ->
    client.getRoom(roomId).getCanonicalAlias() ? roomId

  <CollapsingHeaderView
    headerHeight={300}
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
    }
    renderContent={->
      <View style={{ height: 1000 }}>
      </View>
    }/>

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