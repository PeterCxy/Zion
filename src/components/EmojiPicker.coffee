import React from "react"
import EmojiBoard from 'react-native-emoji-board'
import { BottomSheet } from "./BottomSheet"
import { useInvokeDialogForResult } from "../util/util"

# A thin wrapper over the EmojiSelector library
# that exposes an asynchronous Dialog-like interface
export useEmojiPicker = ->
  useInvokeDialogForResult EmojiPicker

EmojiPicker = ({show, resolvePromise, rejectPromise}) ->
  # EmojiBoard itself does not work well with our layout
  # so we wrap it with our own BottomSheet
  <BottomSheet
    show={show}
    height={280}
    onClose={-> rejectPromise "user cancelled" if rejectPromise?}>
    <EmojiBoard
      showBoard={true}
      hideBackSpace={true}
      onClick={(emoji) -> resolvePromise emoji}/>
  </BottomSheet>