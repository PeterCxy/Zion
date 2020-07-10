import React from "react"
import { ScrollView } from "react-native"
import { BottomSheet } from "./BottomSheet"
import MessageComposer from "./MessageComposer"
import Event from "./events/Event"
import { useInvokeDialogForResult } from "../util/util"

# A bottom sheet modal to compose a message related to a previous message
# e.g. reply / edit
# when the composer is invoked, it returns a promise that resolves with the
# content that has been entered to the MessageComposer
export useAssociatedMessageComposer = (title, origMsg) ->
  useInvokeDialogForResult AssociatedMessageComposer,
    title: title
    origMsg: origMsg

AssociatedMessageComposer = ({show, resolvePromise, rejectPromise, title, origMsg}) ->
  <BottomSheet
    show={show}
    height={250}
    title={title}
    onClose={-> rejectPromise "user cancelled" if rejectPromise?}>
    <ScrollView>
      {
        if origMsg?
          <Event ev={origMsg}/>
      }
    </ScrollView>
    <MessageComposer
      onSendClicked={(text) -> resolvePromise text}/>
  </BottomSheet>