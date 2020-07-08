import React, { useContext, useEffect, useMemo, useState, useRef } from "react"
import EventEmitter from "react-native/Libraries/vendor/emitter/EventEmitter"
import { Banner } from "react-native-paper"
import { translate } from "../util/i18n"
import { MatrixClientContext } from "../util/client"
import { verificationMethods } from "matrix-js-sdk/lib/crypto"
import SASVerificationDialog from "./SASVerificationDialog"

# Used for outgoing verification events
export VerificationEventBus = new EventEmitter()

# A component dedicated to handling verification requests
export default VerificationRequestHandler = () ->
  client = useContext MatrixClientContext

  # Use a ref to track this because we don't want to reset
  # event listeners every time the component updates
  verifyingRef = useRef false

  [verifier, setVerifier] = useState null
  [pendingVerificationRequest, setPendingVerificationRequest] = useState null
  # For accepted pending requests, we should start verification immediately
  # to prevent the other client from initiating another verification on its own
  # because the verifier in this case is "initiated" by us, not the other side
  # TODO: we should probably implement this the Riot way, i.e. show an UI for
  #       choosing which method to use, only initiating the verifier after
  #       the choice; if the other side chooses a verifier before us, use that
  #       instead (we can listen on the `change` event of the pending request).
  #       However, that will introduce a lot of complication in our code.
  #       For now, let's just always make sure WE are the side that initiates
  #       the verifier by not accepting the pending request until the point where
  #       we can create the verifier right away.
  #       And since Zion currently never sends a "pending" verification request,
  #       so this case won't happen between two Zion clients. If we were to do
  #       the same thing as Riot in the future, we will need to re-implement this
  #       the Riot way.
  [isAcceptedPendingRequest, setIsAcceptedPendingRequest] = useState false

  useEffect ->
    onVerificationRequest = (request) ->
      if request.verifier
        # This is triggered when clicking verify
        # in the device list (on Riot Web)
        console.log "has verifier"
        if verifyingRef.current
          console.log "rejecting verification because one is in progress"
          request.verifier.cancel 'Already in progress'
          return
        verifyingRef.current = true
        setVerifier request.verifier
      else if request.pending
        # This is triggered when clicking verify
        # in the cross-verification notification (on Riot Web)
        console.log "pending verification request"
        if not request.methods.includes verificationMethods.SAS
          console.log "Zion only supports SAS verification"
          request.cancel()
          return
        if verifyingRef.current
          console.log "rejecting verification because one is in progress"
          request.cancel()
          return
        verifyingRef.current = true
        # We need to prompt the user to accept the verification
        # before it actually starts
        setPendingVerificationRequest request

    onOutgoingVerification = (verifier) ->
      if verifyingRef.current
        console.log "rejecting verification because one is in progress"
        verifier.cancel 'Already in progress'
        return
      verifyingRef.current = true
      setVerifier verifier

    client.on 'crypto.verification.request', onVerificationRequest
    VerificationEventBus.addListener 'outgoing', onOutgoingVerification

    return ->
      client.removeListener 'crypto.verification.request', onVerificationRequest
      VerificationEventBus.removeListener 'outgoing', onOutgoingVerification
  , []

  bannerActions = useMemo ->
    [
        label: translate("decline")
        onPress: ->
          verifyingRef.current = false
          pendingVerificationRequest.cancel()
          setPendingVerificationRequest null
      ,
        label: translate("accept")
        onPress: ->
          await pendingVerificationRequest.accept()
          verifier =
            pendingVerificationRequest.beginKeyVerification verificationMethods.SAS
          setIsAcceptedPendingRequest true
          setVerifier verifier
          setPendingVerificationRequest null
    ]
  , [pendingVerificationRequest]

  <>
    <Banner
      visible={pendingVerificationRequest?}
      actions={bannerActions}>
      {translate "verification_pending"}
    </Banner>
    {
      if verifier
        <SASVerificationDialog
          verifier={verifier}
          isAcceptedPendingRequest={isAcceptedPendingRequest}
          onDismiss={->
            setIsAcceptedPendingRequest false
            setVerifier null
            verifyingRef.current = false
          }/>
    }
  </>