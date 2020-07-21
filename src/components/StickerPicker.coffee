import React, { useContext, useState } from "react"
import { Text, View } from "react-native"
import { BottomSheet } from "./BottomSheet"
import IntegrationWidget from "./IntegrationWidget"
import { MatrixClientContext } from "../util/client"
import { translate } from "../util/i18n"
import * as integrations from "../util/integrations"
import { useInvokeDialogForResult } from "../util/util"

# The value returned by StickerPicker should be an object
# conforming to the following schema:
# {
#   "content": {
#     "info": {
#       "h": <height>,
#       "w": <width>,
#       "thumbnail_url": <mxc_url>,
#       "thumbnail_info": <ThumbnailInfo, refer to Matrix client-server API docs>,
#       "mimetype": <mime>
#     },
#     "url": <mxc_url>,
#     "descrption": <desc>
#   }
# }
# (Note: this is deduced from the behavior of Dimension and Scalar,
#        and I am not sure if this is a standard or something)
# TODO: support multiple sticker widgets?
export useStickerPicker = ->
  useInvokeDialogForResult StickerPicker

StickerPicker = ({show, resolvePromise, rejectPromise}) ->
  <BottomSheet
    show={show}
    height={280}
    onClose={-> rejectPromise "user cancelled" if rejectPromise?}>
    <StickerPickerInner resolvePromise={resolvePromise}/>
  </BottomSheet>

StickerPickerInner = ({resolvePromise}) ->
  client = useContext MatrixClientContext

  [widget, setWidget] = useState ->
    integrations.getStickerWidgets(client)[0]

  if widget?
    <IntegrationWidget
      widget={widget}
      onSendSticker={(info) -> resolvePromise info}/>
  else
    # TODO: support setting up sticker pickers?
    <View style={{ flex: 1, alignItems: "center", justifyContent: "center" }}>
      <Text style={{ margin: 50, textAlign: "center" }}>{translate "chat_sticker_empty"}</Text>
    </View>