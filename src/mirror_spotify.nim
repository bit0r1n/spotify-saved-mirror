import asyncdispatch, sequtils, strformat, strutils, os, algorithm
import spotify/[ spotifyclient, library, users, playlists, objects/track, objects/error ]
import auth, config, utils

doAssert (existsEnv("SPOTIFY_ID"), existsEnv("SPOTIFY_SECRET")) == (true, true),
  "Missing SPOTIFY_ID or SPOTIFY_SECRET environment variable(s)"

let
  spotifyConfig = getConfig[SpotifyConfig]()

  mirrorPlaylistId = spotifyConfig.mirrorPlaylistId.getIdOfBase62(piePlaylist)
  tracksToIgnore = spotifyConfig.ignoreTracks.mapIt(getIdOfBase62(it, pieTrack))

echo spotifyConfig.ignoreTracks

doAssert mirrorPlaylistId.len != 0, "Spotify.mirror_playlist_id in config should be specified"

proc `$`(track: Track): string = &"{track.artists.mapIt(it.name).join(\", \")} - {track.name}"

proc getAllPlaylistTracks(client: AsyncSpotifyClient, id: string): Future[seq[Track]] {.async.} =
  var offset = 0

  let
    limit = 50
    tracksResponse = await client.getPlaylistTracks(
      playlistId = id, limit = limit, offset = offset)
    totalTracks = tracksResponse.total

  result.add(tracksResponse.items.mapIt(it.track))

  while totalTracks > limit + offset:
    offset = offset + limit
    result.add((await client.getPlaylistTracks(
      playlistId = id, limit = limit, offset = offset)).items.mapIt(it.track))

proc getAllSavedTracks(client: AsyncSpotifyClient): Future[seq[Track]] {.async.} =
  var offset = 0

  let
    limit = 50
    savedTracksResponse = await client.getSavedTracks(limit = limit, offset = offset)
    totalTracks = savedTracksResponse.total

  result.add(savedTracksResponse.items.mapIt(it.track))

  while totalTracks > limit + offset:
    offset = offset + limit
    result.add((await client.getSavedTracks(
      limit = limit, offset = offset)).items.mapIt(it.track))

proc getTracksUntil(source: seq[Track], breakId: string): seq[Track] =
  for track in source:
    if track.id == breakId: break
    if track.id in tracksToIgnore: continue
    result.add track

  if source.len == result.len: result.setLen(0)

proc main() {.async.} =
  let
    authToken = await getToken()
    token = newSpotifyToken(authToken, "", "")
    client = newAsyncSpotifyClient(token)

  echo "Checking user for authorization and playlist owner"

  try:
    let
      selfUser = await client.getCurrentUser()
      checkPlaylist = await client.getPlaylist(mirrorPlaylistId)

    doAssert checkPlaylist.owner.id == selfUser.id,
      "You are not an owner of playlist"
  except SpotifyError:
    raise newException(CatchableError, "Failed to fetch self user or to find playlist")

  echo "Getting items of liked and public playlists"
  let
    savedTracks = await client.getAllSavedTracks()
    mirrorTracks = await client.getAllPlaylistTracks(mirrorPlaylistId)

  let tracksToRemove = mirrorTracks.filterIt(it.id notin savedTracks.mapIt(it.id) and
    it.id notin tracksToIgnore)
  echo "Tracks to remove (missing in saved): ", tracksToRemove
  if tracksToRemove.len != 0:
    for tracksBatch in tracksToRemove.batch(100):
      discard await client.deleteTracksFromPlaylist(mirrorPlaylistId,
        tracksBatch.mapIt("spotify:track:" & it.id))

  let tracksToAdd = if mirrorTracks.len == 0: savedTracks else: savedTracks.getTracksUntil(mirrorTracks[0].id)
  echo "Tracks to add: ", tracksToAdd
  if tracksToAdd.len != 0:
    for tracksBatch in tracksToAdd.batch(100).reversed():
      discard await client.postTracksToPlaylist(mirrorPlaylistId,
        tracksBatch.mapIt("spotify:track:" & it.id), 0)

waitFor main()