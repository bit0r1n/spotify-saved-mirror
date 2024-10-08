# Package

version       = "0.1.1"
author        = "bit0r1n"
description   = "A simple tool to mirror saved tracks to public playlist (i.e. make likes public)"
license       = "MIT"
srcDir        = "src"
bin           = @[ "mirror_spotify", "get_token" ]
binDir        = "build"


# Dependencies

requires "nim >= 2.0.2"
requires "https://github.com/bit0r1n/nimspotify"
