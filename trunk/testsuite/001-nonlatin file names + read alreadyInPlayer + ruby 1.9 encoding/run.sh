#!/bin/bash

mydir=$(dirname "$0")
echo mydir is $mydir

ruby ./2-fill-player.rb -dbf "$mydir/dbf.txt"

