import { InteractionManager } from "react-native"

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