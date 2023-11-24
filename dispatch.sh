#!/bin/bash -ex
# Usage: pass a bash command to execute on each host in parallel

ssh isu1 "cd isucon13-infra && $1" &
ssh isu2 "cd isucon13-infra && $1" &
ssh isu3 "cd isucon13-infra && $1"
wait
