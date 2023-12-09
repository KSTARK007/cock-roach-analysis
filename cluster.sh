#!/bin/bash

NUM_HOSTS=$2

# Function to start CockroachDB on a given node
start_cockroach() {
  local NODE_ID=$1
  local LISTEN_PORT=$2
  local HTTP_PORT=$3
  local JOIN_ADDR=$4
  local CACHE_SIZE=$5

  /users/Khombal2/cockroach/cockroach start --insecure \
    --store=/mydata/node${NODE_ID} \
    --cache=${CACHE_SIZE}GiB \
    --listen-addr=0.0.0.0:${LISTEN_PORT} \
    --http-addr=0.0.0.0:${HTTP_PORT} \
    --join=${JOIN_ADDR} \
    --background

  sleep 2  # Allow some time for the node to start
}

# Function to initialize CockroachDB cluster
init_cockroach() {
  local INIT_HOST=$1

  /users/Khombal2/cockroach/cockroach init --insecure --host=${INIT_HOST}
}

# Generate JOIN_ADDR in a separate loop
JOIN_ADDR=""
for ((i=1; i<=$NUM_HOSTS; i++)); do
  LISTEN_PORT=$((26256 + i))
  JOIN_ADDR="${JOIN_ADDR},0.0.0.0:${LISTEN_PORT}"
done

# Remove leading comma from JOIN_ADDR
JOIN_ADDR=$(echo $JOIN_ADDR | sed 's/^,//')

# Start CockroachDB on each node with the generated JOIN_ADDR
for ((i=1; i<=$NUM_HOSTS; i++)); do
  LISTEN_PORT=$((26256 + i))
  HTTP_PORT=$((8080 + i))

  start_cockroach $i $LISTEN_PORT $HTTP_PORT "$JOIN_ADDR" $1
done

# Initialize CockroachDB on one node
init_cockroach 0.0.0.0:26257

# Check logs for node starting message
grep 'node starting' /mydata/node1/logs/cockroach.log -A 11
