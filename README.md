whine - v1.0
============

Whine adds the "@whine" chat command to pure vanilla Minecraft servers. This means that whenever a player says, for example, `@whine FooBar`, the phone that you set up gets a text message that says `PLAYERNAME: FooBar`.

## Setup

To set up whine, just download it, edit the configuration at the top of the file, and run it with `./whine.sh`.

Note: You should already have a Google account set up with a Google Voice number.

## Dependencies

The biggest dependency is that your server must be running on Linux in a `screen` session.

The only other dependencies are standard *nix utilities like `sed` and `curl`.
