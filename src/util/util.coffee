# Compare if two timestamps (in ms) are exactly the same day
# in the local time zone, while ignoring hours / minutes
export tsSameDay = (ts1, ts2) ->
  d1 = new Date ts1
    .setHours 0, 0, 0, 0
  d2 = new Date ts2
    .setHours 0, 0, 0, 0
  
  d1 == d2