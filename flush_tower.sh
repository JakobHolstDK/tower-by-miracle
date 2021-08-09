#!/usr/bin/env expect

spawn tower-cli empty --all

sleep 1
send "YES\r"

expect "ok="
