import parsecfg, asyncdispatch, os, times, strutils
import spotify/[ spotifyclient, scope ]
import config

let
  expiresIn = 3_600

  appId = getEnv("SPOTIFY_ID")
  appSecret = getEnv("SPOTIFY_SECRET")
  appScopes = @[ ScopeUserLibraryRead, ScopePlaylistModifyPublic ]

proc getToken*(configFilename: string): Future[string] {.async.} =
  var authConfig = getConfig[AuthConfig](configFilename)

  if (authConfig.accessToken.len != 0, authConfig.refreshToken.len != 0,
    authConfig.createdAt != 0) != (true, true, true):
    raise newException(CatchableError,
      "Access token, refresh token or created timestamp are missing, you need to login")

  if now().toTime().toUnix() + 10 > authConfig.createdAt + expiresIn:
    let
      token = newSpotifyToken(authConfig.accessToken, authConfig.refreshToken, "")
      client = newAsyncSpotifyClient(token)

    let updatedToken = await client.refreshToken(appId, appSecret, appScopes)

    authConfig.accessToken = updatedToken.accessToken
    authConfig.refreshToken = updatedToken.refreshToken
    authConfig.createdAt = now().toTime().toUnix()
    configFilename.saveConfig(authConfig)

  return authConfig.accessToken