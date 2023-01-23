#!/usr/bin/env bash
if [[ "$1" == *.html ]]; then
	sed -i 's/<img /<img loading="lazy" /g' "$1"
fi
