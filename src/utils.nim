import strutils

type ParseIdEntity* = enum
  pieTrack
  piePlaylist

proc entityToStr(en: ParseIdEntity): string =
  case en:
  of pieTrack: "track"
  of piePlaylist: "playlist"

proc getIdOfBase62*(str: string, en: ParseIdEntity): string =
  let parts = str.split(':')

  return
    if parts.len == 1: return str
    elif parts.len != 3 or parts[1] != entityToStr(en): return ""
    else: parts[2]

proc batch*[T](s: seq[T], batchSize = 1): seq[seq[T]] =
  var start = 0

  while start < s.len:
    let
      until = min(start + batchSize, s.len)
    result.add s[start ..< until]
    start = until