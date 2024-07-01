import httpclient, os, times
import spotify/[ spotifyclient, scope ]
import config

doAssert (existsEnv("SPOTIFY_ID"), existsEnv("SPOTIFY_SECRET")) == (true, true),
  "Missing SPOTIFY_ID or SPOTIFY_SECRET environment variable(s)"

var authConfig = getConfig[AuthConfig]()

let token = newHttpClient().authorizationCodeGrant(
  getEnv("SPOTIFY_ID"),
  getEnv("SPOTIFY_SECRET"),
  @[
    ScopeUserLibraryRead,
    ScopePlaylistModifyPublic
  ]
)

authConfig.accessToken = token.accessToken
authConfig.refreshToken = token.refreshToken
authConfig.createdAt = now().toTime().toUnix()
saveConfig(authConfig)

echo "Check \"config.ini\" file for received token"
# echo authConfig