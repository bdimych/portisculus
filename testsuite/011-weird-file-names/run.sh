#!/bin/bash

set -e -o pipefail

ruby 2-fill-player.rb -dbf ./testsuite/011-weird-file-names/-.txt

