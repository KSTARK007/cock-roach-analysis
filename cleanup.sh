#!/bin/bash

# Function to gracefully shut down CockroachDB on a given node
shutdown_cockroach() {
  local PID=$1
  local wait_seconds=5
  local retries=3

  for attempt in $(seq 1 ${retries}); do
    echo "Attempt ${attempt} to shut down Node ${PID}..."

    # Send TERM signal for graceful shutdown
    kill -TERM ${PID}

    # Polling for a maximum of 10 seconds to check if the process has exited
    local count=0
    while ps -p ${PID} > /dev/null; do
      if [ ${count} -eq ${wait_seconds} ]; then
        echo "Forcefully terminating Node ${PID}..."
        kill -KILL ${PID}
        break
      fi
      echo "Waiting for Node ${PID} to shut down... (${count}s)"
      sleep 1
      ((count++))
    done

    # Check if the process is still running
    if ! ps -p ${PID} > /dev/null; then
      echo "Node ${PID} has been shut down."
      return 0
    fi

    echo "Node ${PID} could not be shut down in attempt ${attempt}. Retrying..."
  done

  echo "Failed to shut down Node ${PID} after ${retries} attempts."
  return 1
}

# Get the process IDs of the nodes
NODE_PIDS=$(ps -ef | grep cockroach | grep -v grep | awk '{print $2}')

# Calculate the number of hosts based on the number of node PIDs
NUM_HOSTS=$(echo "${NODE_PIDS}" | wc -w)

# Shut down each node gracefully
for PID in ${NODE_PIDS}; do
  if ! shutdown_cockroach ${PID}; then
    echo "Proceeding to the next node despite the failure."
  fi
done

# Remove the nodes' data stores
for dir in /mydata/node[0-9]*; do
  if [ -d "$dir" ]; then
    rm -rf "$dir"
    echo "Data store in '$dir' has been removed."
  else
    echo "Data store directory '$dir' does not exist or has already been removed."
  fi
done

echo "All relevant nodes data stores have been removed."
