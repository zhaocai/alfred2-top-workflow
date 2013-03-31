#!/usr/bin/env zsh
PASS=$(Authenticate.app/Contents/MacOS/Authenticate -get password)
if [ "$PASS" = "(null)" ] ; then
    Authenticate.app/Contents/MacOS/Authenticate
    PASS=$(Authenticate.app/Contents/MacOS/Authenticate -get password)
fi
echo $PASS | sudo -S "$@"

