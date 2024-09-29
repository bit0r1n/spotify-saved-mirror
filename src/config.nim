import parsecfg, asyncdispatch, os, strutils

let
  configFilename = "config.ini"
  authKey = "Auth"
  spotifyKey = "Spotify"

type
  AuthConfig* = object
    accessToken*, refreshToken*: string
    createdAt*: int
  SpotifyConfig* = object
    mirrorPlaylistId*: string
    ignoreTracks*: seq[string]

proc getConfig*[T](): auto =
  var dict = newConfig()
  if not fileExists(configFilename):
    # auth
    dict.setSectionKey(authKey, "access_token", "")
    dict.setSectionKey(authKey, "refresh_token", "")
    dict.setSectionKey(authKey, "created_at", "")

    # spotify
    dict.setSectionKey(spotifyKey, "mirror_playlist_id", "")
    dict.setSectionKey(spotifyKey, "ignore_tracks", "")

    dict.writeConfig(configFilename)
  else:
    dict = loadConfig(configFilename)

  when T is AuthConfig:
    let createdAt = try:
      dict.getSectionValue(authKey, "created_at").parseInt()
    except:
      0

    return AuthConfig(
      accessToken: dict.getSectionValue(authKey, "access_token"),
      refreshToken: dict.getSectionValue(authKey, "refresh_token"),
      createdAt: createdAt
    )

  elif T is SpotifyConfig:
    return SpotifyConfig(
      mirrorPlaylistId: dict.getSectionValue(spotifyKey, "mirror_playlist_id"),
      ignoreTracks: dict.getSectionValue(spotifyKey, "ignore_tracks").splitWhitespace
    )
  else:
    raise newException(CatchableError, "unknown config type")

proc saveConfig*[T](config: T) =
  discard getConfig[T]()

  var dict = loadConfig(configFilename)

  when T is AuthConfig:
    dict.setSectionKey(authKey, "access_token", config.accessToken)
    dict.setSectionKey(authKey, "refresh_token", config.refreshToken)
    dict.setSectionKey(authKey, "created_at", $config.createdAt)

  elif T is SpotifyConfig:
    dict.setSectionKey(spotifyKey, "mirror_playlist_id", config.mirrorPlaylistId)
    dict.setSectionKey(spotifyKey, "ignore_tracks", config.ignoreTracks.join(","))

  dict.writeConfig(configFilename)