#!/bin/bash
set -Eeuox pipefail

firefox_class_name="firefox"
IDE_class_name="jetbrains"
sleep_time=1

declare primary_monitor_xsize_px

function set_primary_monitor_xsize() {
  local regex=".* primary ([0-9]+)x[0-9]+\+[0-9]+\+[0-9]+.*"
  local output=$(xrandr --current)
  if [[ $output =~ $regex ]]; then
    primary_monitor_xsize_px="${BASH_REMATCH[1]}"
  fi
}

function isWindowExist() {
  local class_name="$1"
  local found=$(wmctrl -lx | awk -v class="${class_name}" '
    BEGIN{found=0}
    $3 ~ class {
      found=1
    }
    END {
      print found
    }
  '
  )
  echo "${found}"
}

function isWindowOnPrimaryMonitor() {
  local class_name="$1"
  local geometry="${primary_monitor_xsize_px}"
  local found=$(wmctrl -lxG | awk -v class="${class_name}" -v geometry="${geometry}" '
    BEGIN{found=0}
    $7 ~ class && $3 < geometry {
      found=1
    }
    END {
      print found
    }
  '
  )
  echo "${found}"
}

function move_window() {
  local moving_window_class="$1"
  wmctrl -x -r "${moving_window_class}" -e 0,"${primary_monitor_xsize_px}",0,-1,-1
}

function return_window() {
  local returning_window_class="$1"
  wmctrl -x -r "${returning_window_class}" -e 0,0,0,-1,-1
}

function main() {
  set_primary_monitor_xsize
  if [[ "$(isWindowOnPrimaryMonitor "${firefox_class_name}")" == "1" ]]; then
    move_window "${firefox_class_name}"
  fi
  while [[ "$(isWindowExist "${IDE_class_name}")" == "1" ]]; do
    sleep ${sleep_time}
  done
  return_window "${firefox_class_name}"
}

function cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

main
cleanup
