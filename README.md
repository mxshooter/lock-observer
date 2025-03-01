# lock-observer

A tiny Swift program to run a command whenever the screen locks or unlocks \
(I use it for set my status offline or online at simple webpage)

```sh
# lock-observer [OPTIONS] <onlock_command> <onunlock_command>
lock-observer ./onlock ./onunlock
```

```sh
# add to launchctl (start on login)
serviceman add --user \
    --path "$PATH" \
    ./lock-observer ./examples/mount-network-shares.sh
```

# Table of Contents

- [Acknowledgement](#ack)
- [Install](#install)
- [Run on Login](#run-on-login)
  - [With serviceman](#with-serviceman)
  - [With a plist template](#with-a-plist-template)
- [Build from Source](#build-from-source)
- [Publish Release](#publish-release)
- [Similar Products](#similar-products)

# Acknowledgement

Forked from [coolaj86/lock-observer](https://github.com/coolaj86/lock-observer).
Another more professional fork [smartwatermelon/run-on-macos-screen-events](https://github.com/smartwatermelon/run-on-macos-screen-events).

# Install

1. Download
   ```sh
   curl --fail-with-body -L -O https://github.com/coolaj86/lock-observer/releases/download/v1.0.0/lock-observer-v1.0.0.tar.gz
   ```
2. Extract
   ```sh
   tar xvf ./lock-observer-v1.0.0.tar.gz
   ```
3. Allow running even though it's unsigned
   ```sh
   xattr -r -d com.apple.quarantine ./lock-observer
   ```
4. Move into your `PATH`
   ```sh
   mv ./lock-observer ~/bin/
   ```

# Run on Login

You'll see notifications similar to these when adding launchctl services yourself:

<img width="376" alt="Background Items Added" src="https://github.com/user-attachments/assets/362d180b-51e6-4e5a-a9be-8cdc356e5b34">

<img width="827" alt="Login Items from unidentified developer" src="https://github.com/user-attachments/assets/fb8fce4c-035a-40ae-8f37-70c28e67ad87">

## With `serviceman`

1. Install `serviceman`
   ```sh
   curl --fail-with-body -sS https://webi.sh/serviceman | sh
   source ~/.config/envman/PATH.env
   ```
2. Register with Launchd \
   (change `COMMAND_GOES_HERE` to your command)

   ```sh
   serviceman add --user \
       --path "$PATH" \
       ~/bin/lock-observer COMMAND_GOES_HERE
   ```

## With a plist template

1. Download the template plist file
   ```sh
   curl --fail-with-body -L -O https://raw.githubusercontent.com/coolaj86/lock-observer/main/examples/lock-observer.COMMAND_LABEL_GOES_HERE.plist
   ```
2. Change the template variables to what you need:

   - `USERNAME_GOES_HERE` (the result of `$(id -u -n)` or `echo $USER`)
   - `COMMAND_LABEL_GOES_HERE` (lowercase, dashes, no spaces)
   - `COMMAND_GOES_HERE` (the example uses `./examples/mount-network-shares.sh`)

3. Rename and move the file to `~/Library/LaunchDaemons/`
   ```sh
   mv ./lock-observer.COMMAND_LABEL_GOES_HERE.plist ./lock-observer.example-label.plist
   mv ./lock-observer.*.plist ~/Library/LaunchDaemons/
   ```
4. Register using `launchctl`
   ```sh
   launchctl load -w ~/Library/LaunchAgents/lock-observer.*.plist
   ```

## View logs

```sh
tail -f ~/.local/share/lock-observer.*/var/log/lock-observer.*.log
```

# Build from Source

1. Install XCode Tools \
   (including `git` and `swift`)
   ```sh
   xcode-select --install
   ```
2. Clone and enter the repo
   ```sh
   git clone https://github.com/coolaj86/lock-observer.git
   pushd ./lock-observer/
   ```
3. Build with `swiftc`
   ```sh
   swiftc ./lock-observer.swift
   ```

# Publish Release

1. Git tag and push
   ```sh
   git tag v1.0.x
   git push --tags
   ```
2. Create a release \
   <https://github.com/coolaj86/lock-observer/releases/new>
3. Tar and upload
   ```sh
   tar cvf ./lock-observer-v1.0.x.tar ./lock-observer
   gzip ./lock-observer-v1.0.x.tar
   open .
   ```

# Similar Products

- [How to run a command on lock/unlock](https://apple.stackexchange.com/questions/159216/run-a-program-script-when-the-screen-is-locked-or-unlocked) (the snippets from which this repo grew)
- [EventScripts](https://apps.apple.com/us/app/eventscripts/id525319418?l=en&mt=12)
- [HammarSpoon: caffeinate.watcher](https://www.hammerspoon.org/docs/hs.caffeinate.watcher.html)
