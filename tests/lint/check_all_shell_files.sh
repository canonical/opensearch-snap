#!/usr/bin/bash

FILES="$(find scripts/ -type f -exec bash -c 'head -n 1 {} | grep sh > /dev/null; echo {}' \;)"

for i in ${FILES}; do 
    shellcheck $i;
done