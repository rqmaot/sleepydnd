#!/bin/sh
printf '\033c\033]0;%s\a' sleepydnd
base_path="$(dirname "$(realpath "$0")")"
"$base_path/sleepydnd.x86_64" "$@"
