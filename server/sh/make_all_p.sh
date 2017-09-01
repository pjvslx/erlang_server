#!/bin/bash
rm -f ebin/*.beam
erl -pa ebin -noinput -eval "case mmake:all(4,[]) of up_to_date -> halt(0); error -> halt(1) end."

LANGBAK=${LANG}
export LANG="en_US"
echo -e "$(svn info | grep "Revision")" > ebin/game_version
echo -e "$(svn info | grep "Last Changed Dat")" >> ebin/game_version
export LANG=${LANGBAK}
