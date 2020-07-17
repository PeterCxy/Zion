import React, { useCallback, useMemo, useState } from "react"
import { useWindowDimensions, InteractionManager, Vibration } from "react-native"
import { translate } from "./i18n"

# From react-native-paper
export DEFAULT_APPBAR_HEIGHT = 56

# Generate a random string, used for internal IDs for temporary files
# NOT CRYPTOGRAPHYCALLY SECURE
DICTIONARY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
export randomId = (len) ->
  res = ''
  for i in [0..len]
    res += DICTIONARY.charAt Math.floor Math.random() * DICTIONARY.length
  return res

# Compare if two timestamps (in ms) are exactly the same day
# in the local time zone, while ignoring hours / minutes
export tsSameDay = (ts1, ts2) ->
  d1 = new Date ts1
    .setHours 0, 0, 0, 0
  d2 = new Date ts2
    .setHours 0, 0, 0, 0
  
  d1 == d2

# Return true if the URL is an externel web address
export isWebAddr = (url) ->
  (url.startsWith('http:') or url.startsWith('https:')) and not (url.startsWith('https://matrix.to'))

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

# Extract file name from a URL
export extractUrlFileName = (url) ->
  if url.endsWith '/'
    url = url[0...url.length - 1]
  url[url.lastIndexOf('/') + 1...]

# Fit an image inside the window, considering both
# the original dimensions and the window size
export useFitImageDimensions = (origWidth, origHeight) ->
  windowWidth = useWindowDimensions().width
  windowHeight = useWindowDimensions().height
  windowScale = useWindowDimensions().scale

  # The memo value does NOT depend on windowHeight
  # because it might change when keyboard is shown
  # we don't want UI to completely change
  # just because the keyboard is shown
  useMemo ->
    return [null, null] unless origWidth? and origHeight?
    w = origWidth / windowScale
    if w > windowWidth * 0.6
      w = 0.6 * windowWidth
    if w < 50 * windowScale
      w = 50 * windowScale
    h = origHeight / origWidth * w
    if h > windowHeight * 0.9
      h = windowHeight * 0.9
    if h < 20 * windowScale
      h = 20 * windowScale
      w = origWidth / origHeight * h
      if w > windowWidth * 0.6
        w = windowWidth * 0.6
    [w, h]
  , [ windowWidth, windowScale, origWidth, origHeight ]

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
export useInvokeDialogForResult = (Component) ->
  [resolvePromise, setResolvePromise] = useState null
  [rejectPromise, setRejectPromise] = useState null
  [componentExtraProps, setExtraProps] = useState null
  [show, setShow] = useState false

  invokeDialogForResult = useCallback (extraProps) ->
    new Promise (resolve, reject) ->
      setResolvePromise (orig) ->
        if orig?
          reject "Cannot handle multiple simultaneous requests" 
          return orig

        (res) ->
          setShow false
          setRejectPromise null
          setResolvePromise null
          setExtraProps null
          resolve res
      setRejectPromise (orig) ->
        if orig?
          reject "Cannot handle multiple simultaneous requests" 
          return orig

        (err) ->
          setShow false
          setRejectPromise null
          setResolvePromise null
          setExtraProps null
          reject err
      setExtraProps (orig) ->
        if orig?
          reject "Cannot handle multiple simultaneous requests" 
          return orig

        return extraProps
      setShow true
  , []

  renderedComponent =
    <Component
      show={show}
      rejectPromise={rejectPromise}
      resolvePromise={resolvePromise}
      {...componentExtraProps}/>

  [renderedComponent, invokeDialogForResult]