#!/bin/bash
files=(
"/tmp/dummy_plays_status"
"/tmp/dummy_plays_monitor"
"/tmp/dummy_plays_start"
"/tmp/dummy_plays_stop"
"/tmp/dummy_plays_pre_promote"
"/tmp/dummy_plays_pre_start"
"/tmp/dummy_plays_pre_stop"
"/tmp/dummy_plays_pre_demote"
"/tmp/dummy_plays_post_promote"
"/tmp/dummy_plays_post_start"
"/tmp/dummy_plays_post_stop"
"/tmp/dummy_plays_post_demote"
"/tmp/dummy_plays_promote"
"/tmp/dummy_plays_demote"
)
actions=(
"ERROR" "FAILED_MASTER" "RUNNING_MASTER" "SUCCESS" "NOT_RUNNING"
)
plays_max=3
files_size=${#files[@]}
n=$((files_size-1))
actions_size=${#actions[@]}

while true; do
  file_ind=$(( RANDOM % $actions_size ))
  touch ${files[$i]}
  filetail=$(tail -1 "${files[$file_ind]}")
  if [ -z "${filetail}" ] ; then
    plays=$(( ( RANDOM % $plays_max )  + 1 ))
    action_ind=$(( RANDOM % $actions_size ))
    for i in $(seq 1 $plays) ; do
      echo "${actions[$action_ind]}" >> "${files[$file_ind]}"
    done
  fi
  for i in $(seq 1 $n) ; do
    content="$(cat ${files[$i]} 2>/dev/null)"
    [ "${content}" ] && echo "Dummy plays in ${files[$i]} are: `echo ${content}`"
  done
  sleep 0.1
done
