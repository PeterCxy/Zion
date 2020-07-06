import React from "react"
import { ScrollView, View } from "react-native"
import { Appbar } from "react-native-paper"
import PreferenceCategory from "../components/preferences/PreferenceCategory"
import Preference from "../components/preferences/Preference"
import { translate } from "../util/i18n"

export default Settings = ({navigation}) ->
  <>
    <Appbar.Header>
      <Appbar.BackAction
        onPress={-> navigation.goBack()}/>
      <Appbar.Content
        title={translate "settings"}/>
    </Appbar.Header>
    <ScrollView style={{ height: '100%', width: '100%' }}>
      <View style={{ flexDirection: 'column' }}>
        <PreferenceCategory
          title={translate "settings_account"}>
          <Preference
            icon="lock"
            title={translate "settings_account_security"}/>
        </PreferenceCategory>
      </View>
    </ScrollView>
  </>