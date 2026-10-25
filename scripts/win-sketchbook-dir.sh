#!/bin/sh
# Windows 版 Arduino IDE のスケッチブックフォルダを WSL のパスで出力する。
#
# 1. Arduino IDE 2.x の設定（%USERPROFILE%\.arduinoIDE\arduino-cli.yaml）の
#    directories.user を使う。
# 2. 設定がなければ「ドキュメント」フォルダ配下の Arduino を使う。

set -eu

userprofile=$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')
if [ -z "$userprofile" ]; then
	echo "error: Windows の USERPROFILE を取得できません" >&2
	exit 1
fi

config="$(wslpath -u "$userprofile")/.arduinoIDE/arduino-cli.yaml"
dir=

if [ -f "$config" ]; then
	dir=$(sed -n '/^directories:/,/^[^[:space:]]/s/^[[:space:]]\{1,\}user:[[:space:]]*//p' "$config" \
		| tr -d "\r\"'" | head -n 1)
fi

if [ -z "$dir" ]; then
	docs=$(powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')" | tr -d '\r')
	dir="$docs\\Arduino"
fi

wslpath -u "$dir"
