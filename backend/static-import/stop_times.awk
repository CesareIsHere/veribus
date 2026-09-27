# stop_times.txt -> trip_id,seq,stop_id,departure_s for the trips in keep.tsv (trip_id TAB late t/f).
# Streams straight into network_import.stop_time: the 5 million raw rows never land in the database.
#   awk -f stop_times.awk keep.tsv stop_times.txt
BEGIN { FS = ","; OFS = "," }

FNR == NR { split($0, k, "\t"); keep[k[1]] = k[2]; next }

FNR == 1 {
  sub(/^\357\273\277/, ""); sub(/\r$/, "")
  for (i = 1; i <= NF; i++) col[$i] = i
  fields = NF
  next
}

{
  sub(/\r$/, "")
  # A quoted comma would shift the columns: stop loudly rather than import garbage.
  if (NF != fields) { print "stop_times.txt line " FNR ": unexpected field count" > "/dev/stderr"; exit 1 }
  trip = $col["trip_id"]
  if (!(trip in keep)) next
  t = $col["departure_time"] != "" ? $col["departure_time"] : $col["arrival_time"]
  if (t == "") next # trips without times are dropped, as Roma mobile does
  split(t, hms, ":")
  s = hms[1] * 3600 + hms[2] * 60 + hms[3]
  if (keep[trip] == "t" && s < 86400) next # yesterday's trip: only its part after midnight
  print trip, $col["stop_sequence"], $col["stop_id"], s
}
