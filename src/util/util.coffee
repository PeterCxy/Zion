import React, { useCallback, useState } from "react"
import { InteractionManager, Vibration } from "react-native"
import { translate } from "./i18n"

# From react-native-paper
export DEFAULT_APPBAR_HEIGHT = 56

# Compare if two timestamps (in ms) are exactly the same day
# in the local time zone, while ignoring hours / minutes
export tsSameDay = (ts1, ts2) ->
  d1 = new Date ts1
    .setHours 0, 0, 0, 0
  d2 = new Date ts2
    .setHours 0, 0, 0, 0
  
  d1 == d2

# Run a function after the current interaction finishes
# and return a promise that resolves after the callback
# has been run with its return value
export asyncRunAfterInteractions = (callback) ->
  new Promise (resolve, reject) ->
    InteractionManager.runAfterInteractions ->
      try
        # Even if callback returns a promise, it will be
        # fine, since `resolve` automatically recognizes
        # the case.
        resolve callback()
      catch err
        reject err

# Perform a long-press haptic feedback
# TODO: maybe improve on this haptic feedback pattern
#       (e.g. use the one from Pixels?)
export performHapticFeedback = ->
  Vibration.vibrate 20

# Format time according to what is defined in the current locale
export formatTime = (date) ->
  translate "time_format_hour_minute",
    ('' + date.getHours()).padStart(2, '0'),
    ('' + date.getMinutes()).padStart(2, '0')

# A React hook that provides a means to
# invoke a dialog (or dialog-like) modal component and wait for its result
# This can be used to prompt for user input
# The component must accept 3 properties:
#  - show: whether the dialog should show
#  - resolvePromise: the function to resolve the promise returning result
#  - rejectPromise: the function to reject the promise returning result
# The modal component should pass the result via the above two functions
# This function returns 2 values
#  [renderedComponent, invokeDialogForResult]
# where the first value `renderedComponent` must be added to the React DOM
# while the second is a function that returns a promise which resolves
# or rejects when the user finishes or dismisses the dialog
export useInvokeDialogForResult = (Component, extraProps = {}) ->
  [resolvePromise, setResolvePromise] = useState null
  [rejectPromise, setRejectPromise] = useState null
  [show, setShow] = useState false

  invokeDialogForResult = useCallback ->
    new Promise (resolve, reject) ->
      setResolvePromise (orig) ->
        if orig?
          reject "Cannot handle multiple simultaneous requests" 
          return orig

        (res) ->
          setShow false
          setRejectPromise null
          setResolvePromise null
          resolve res
      setRejectPromise (orig) ->
        if orig?
          reject "Cannot handle multiple simultaneous requests" 
          return orig

        (err) ->
          setShow false
          setRejectPromise null
          setResolvePromise null
          reject err
      setShow true
  , []

  renderedComponent =
    <Component
      show={show}
      rejectPromise={rejectPromise}
      resolvePromise={resolvePromise}
      {...extraProps}/>

  [renderedComponent, invokeDialogForResult]