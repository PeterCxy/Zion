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
          onDismiss={->
            setVerifier null
            verifyingRef.current = false
          }/>
    }
  </>