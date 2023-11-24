#!/bin/bash -ex
# Usage: Should be run on isu1, right after starting a benchmark

# run ./dispatch.sh "make reset-log" first to rotate logs

# kill $(lsof -t -i:8080) # kill pprof browser
# go tool pprof -seconds 60 -http=0.0.0.0:8081 ~/webapp/go/isucholar http://localhost:6060/debug/pprof/profile
./dispatch.sh "git pull"

sleep 70

ssh -t isu1 "cd isucon13-infra && make alp > output/alp.txt" &
ssh -t isu2 "cd isucon13-infra && make ptq > /tmp/ptq.txt" &
wait

scp isu2:/tmp/ptq.txt isu1:~/isucon13-infra/output/ptq.txt
ssh -t isu1 "cd isucon13-infra && git add output/. && git commit -m \"benchmark result\" && git push"

git pull & 
./dispatch.sh "git pull" &
wait

# Open to view flamegrph: http://localhost:8081

# Download flamegraph:
# wget -O flamegraph.htm http://localhost:8081/ui/flamegraph
# open flamegraph.htm
