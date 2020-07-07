import React, { useCallback, useContext, useEffect, useState } from "react"
import { Text, View } from "react-native"
import { ActivityIndicator, Button, Dialog, Paragraph, Snackbar } from "react-native-paper"
import { translate } from "../util/i18n"

PHASE_CANCELLED = -2
PHASE_WAITING = -1
PHASE_START = 0
PHASE_SHOW_SAS = 1
PHASE_FINISHED = 2

renderCancelled = (onDismiss) ->
  <Snackbar
    visible={true}
    onDismiss={onDismiss}
    duration={Snackbar.DURATION_SHORT}
    action={{
      label: translate("ok"),
      onPress: onDismiss
    }}>
  {translate "verification_cancelled"}
  </Snackbar>

renderCancelButton = (verifier, setPhase) ->
  <Button
    onPress={->
      verifier.cancel 'User cancel'
      setPhase PHASE_CANCELLED
    }>
    {translate "cancel"}
  </Button>

renderDialogContentStart = (verifier, setPhase) ->
  <>
    <Dialog.Content>
      <Paragraph>
        {
          if verifier.initiatedByMe
            # Outgoing
            # (when the user clicks "verify" on the notification in Riot Web
            #  after initially logging in, and then accepts on this side,
            #  that also counts as an "outgoing" verification)
            translate "verification_outgoing", verifier.deviceId
          else
            translate "verification_start", verifier.userId
        }
      </Paragraph>
    </Dialog.Content>
    <Dialog.Actions>
      {renderCancelButton verifier, setPhase}
      <Button
        onPress={->
          setPhase PHASE_WAITING
          try
            await verifier.verify()
            setPhase PHASE_FINISHED
          catch err
            setPhase PHASE_CANCELLED
        }>
        {translate "continue"}
      </Button>
    </Dialog.Actions>
  </>

renderDialogContentWaiting = (verifier, setPhase) ->
  <>
    <Dialog.Content style={{ flexDirection: "row" }}>
      <ActivityIndicator animating={true}/>
      <Text style={{ marginStart: 10 }}>{translate "verification_waiting"}</Text>
    </Dialog.Content>
    <Dialog.Actions>
      {renderCancelButton verifier, setPhase}
    </Dialog.Actions>
  </>

renderDialogContentSas = (verifier, sasEv, setPhase) ->
  <>
    <Dialog.Content style={{ width: '100%' }}>
      <Paragraph>{translate "verification_match_prompt"}</Paragraph>
      <View
        style={{
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "center",
          flexWrap: "wrap",
          marginStart: -15,
          width: 280
        }}>
      {
        sasEv.sas.emoji.map ([emoji, desc], index) ->
          <View
            key={index}
            style={{
              width: 70,
              height: 70,
              marginTop: 10
              alignItems: "center",
              justifyContent: "center"
            }}>
            <Text style={{ fontSize: 40 }}>{emoji}</Text>
            <Text numberOfLines={1} style={{ fontSize: 11 }}>{desc}</Text>
          </View>
      }
      </View>
    </Dialog.Content>
    <Dialog.Actions style={{ flexWrap: 'wrap' }}>
      {renderCancelButton verifier, setPhase}
      <Button
        onPress={->
          verifier.cancel 'Mismatch'
          setPhase PHASE_CANCELLED
        }>
        {translate "verification_they_dont_match"}
      </Button>
      <Button
        onPress={->
          setPhase PHASE_WAITING
          sasEv.confirm()
        }>
        {translate "verification_they_match"}
      </Button>
    </Dialog.Actions>
  </>

renderDialogContentFinished = (onDismiss) ->
  <>
    <Dialog.Content>
      <Paragraph>{translate "verification_finished"}</Paragraph>
    </Dialog.Content>
    <Dialog.Actions>
      <Button
        onPress={onDismiss}>
        {translate "ok"}
      </Button>
    </Dialog.Actions>
  </>

export default SASVerificationDialog = ({verifier, onDismiss}) ->
  [phase, setPhase] = useState PHASE_START
  [sasEv, setSasEv] = useState null

  useEffect ->
    if verifier.cancelled
      setPhase PHASE_CANCELLED
    
    onCancel = ->
      setPhase PHASE_CANCELLED
    onShowSas = (e) ->
      setSasEv e
      setPhase PHASE_SHOW_SAS

    verifier.on 'cancel', onCancel
    verifier.on 'show_sas', onShowSas

    return ->
      verifier.removeListener 'cancel', onCancel
      verifier.removeListener 'show_sas', onShowSas
  , []

  if phase == PHASE_CANCELLED
    renderCancelled onDismiss
  else
    <Dialog
      visible={true}
      onDismiss={onDismiss}
      dismissable={false}>
      <Dialog.Title>{translate "verification_title"}</Dialog.Title>
      {
        switch phase
          when PHASE_START
            renderDialogContentStart verifier, setPhase
          when PHASE_WAITING
            renderDialogContentWaiting verifier, setPhase
          when PHASE_SHOW_SAS
            renderDialogContentSas verifier, sasEv, setPhase
          when PHASE_FINISHED
            renderDialogContentFinished onDismiss
      }
    </Dialog>