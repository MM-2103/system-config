#!/usr/bin/env bash

cliphist list | hyprlauncher --dmenu | cliphist decode | wl-copy
