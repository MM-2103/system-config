#!/usr/bin/env bash
case "$1" in 
        suspend) 
            killall -STOP gnome-shell         
            ;;
            resume)
            killall -CONT gnome-shell
            ;;
esac 
