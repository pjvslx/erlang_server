#!/bin/bash
rm -f ebin/*.beam
erl -make

LANGBAK=${LANG}
export LANG="en_US"
echo -e "$(svn info | grep "Revision")" > ebin/game_version
echo -e "$(svn info | grep "Last Changed Dat")" >> ebin/game_version
export LANG=${LANGBAK}
