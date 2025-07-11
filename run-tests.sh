#!/bin/bash -e

if [ -z ${3+x} ]; then
  echo "+---------------------------------------------------------------------------------+"
  echo "| This script fetches a bearer token, so you have to provide authentication       |"
  echo "| Usage: ./run-tests.sh <hostAddress> <username> <password>                       |"
  echo "| Usage: ./run-tests.sh vmname-proxy.orbis.dedalus.com doctor safePassword        |"
  echo "+---------------------------------------------------------------------------------+"
  exit 1
fi

source ./get-token.sh

mvn clean verify

