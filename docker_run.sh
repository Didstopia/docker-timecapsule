#!/bin/bash
./docker_build.sh
docker run -p 548:548 -p 636:636 -p 9:9 -p 5353:5353/udp --name timemachine -h TimeMachine -v $(pwd)/DATA/timemachine:/timemachine -v $(pwd)/DATA/netatalk:/var/state/netatalk --rm didstopia/timecapsule:latest
