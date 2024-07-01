import asyncdispatch, sequtils, strformat, strutils, os, algorithm
import spotify/[ spotifyclient, library, users, playlists, objects/track ]
import auth, config, utils

doAssert (existsEnv("SPOTIFY_ID"), existsEnv("SPOTIFY_SECRET")) == (true, true),
  "Missing SPOTIFY_ID or SPOTIFY_SECRET environment variable(s)"

let
  spotifyConfig = getConfig[SpotifyConfig]()

  mirrorPlaylistId = spotifyConfig.mirrorPlaylistId.getIdOfBase62(piePlaylist)
  tracksToIgnore = spotifyConfig.ignoreTracks.mapIt(getIdOfBase62(it, pieTrack))

doAssert mirrorPlaylistId.len != 0, "Spotify.mirror_playlist_id in config should be specified"

proc `$`(track: Track): string = &"{track.artists.mapIt(it.name).join(\", \")} - {track.name}"

proc getAllPlaylistTracks(client: AsyncSpotifyClient, id: string): Future[seq[Track]] {.async.} =
  var offset = 0

  let
    limit = 50
    tracksResponse = (await client.getPlaylistTracks(
      playlistId = id, limit = limit, offset = offset)).data
    totalTracks = tracksResponse.total

  result.add(tracksResponse.items.mapIt(it.track))

  while totalTracks > limit + offset:
    offset = offset + limit
    result.add((await client.getPlaylistTracks(
      playlistId = id, limit = limit, offset = offset)).data.items.mapIt(it.track))

proc getAllSavedTracks(client: AsyncSpotifyClient): Future[seq[Track]] {.async.} =
  var offset = 0

  let
    limit = 50
    savedTracksResponse = (await client.getSavedTracks(limit = limit, offset = offset)).data
    totalTracks = savedTracksResponse.total

  result.add(savedTracksResponse.items.mapIt(it.track))

  while totalTracks > limit + offset:
    offset = offset + limit
    result.add((await client.getSavedTracks(
      limit = limit, offset = offset)).data.items.mapIt(it.track))

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
  let
    selfUser = await client.getCurrentUser()
    checkPlaylist = await client.getPlaylist(mirrorPlaylistId)

  doAssert selfUser.isSuccess, "Failed to fetch self user"

  doAssert checkPlaylist.isSuccess and checkPlaylist.data.owner.id == selfUser.data.id,
    "Failed to find playlist or you are not an owner of playlist"

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

  let tracksToAdd = savedTracks.getTracksUntil(mirrorTracks[0].id)
  echo "Tracks to add: ", tracksToAdd
  if tracksToAdd.len != 0:
    for tracksBatch in tracksToAdd.batch(100).reversed():
      discard await client.postTracksToPlaylist(mirrorPlaylistId,
        tracksBatch.mapIt("spotify:track:" & it.id), 0)

waitFor main()