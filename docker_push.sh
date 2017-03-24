#!/bin/bash
./docker_build.sh
docker tag didstopia/timecapsule:latest didstopia/timecapsule:latest
docker push didstopia/timecapsule:latest