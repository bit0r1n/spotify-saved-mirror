# Package

version       = "0.1.0"
author        = "bit0r1n"
description   = "Simple Spotify saved tracks mirror to playlist"
license       = "MIT"
srcDir        = "src"
bin           = @[ "mirror_spotify", "get_token" ]
binDir        = "build"


# Dependencies

requires "nim >= 2.0.2"
requires "spotify#head"
