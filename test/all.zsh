#!/usr/bin/env zsh

cd "$0:A:h"
integer r=0

echo Widgets tests
./widgets.zsh $@ || r=$?

echo Functions tests
./functions.zsh $@ || r=$?

return $r
