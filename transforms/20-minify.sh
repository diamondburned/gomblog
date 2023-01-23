#!/usr/bin/env bash
if [[ "$MINIFY" != "" ]]; then
	case "${1##*.}" in
	html|css|js)
		minify -o "$1.tmp" "$1"
		mv "$1.tmp" "$1"
		;;
	json)
		jq -c . "$1" > "$1.tmp"
		mv "$1.tmp" "$1"
		;;
	esac
fi
