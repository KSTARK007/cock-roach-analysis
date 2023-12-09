#!/bin/bash

# Function to gracefully shut down CockroachDB on a given node
shutdown_cockroach() {
  local PID=$1
  local wait_seconds=10
  local retries=3

  for attempt in $(seq 1 ${retries}); do
    echo "Attempt ${attempt} to shut down Node ${PID}..."

    # Send TERM signal for graceful shutdown
    sudo kill -TERM ${PID}

    # Polling for a maximum of 10 seconds to check if the process has exited
    local count=0
    while ps -p ${PID} > /dev/null; do
      if [ ${count} -eq ${wait_seconds} ]; then
        echo "Forcefully terminating Node ${PID}..."
        sudo kill -KILL ${PID}
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
NODE_PIDS=$(ps -ef | grep "cockroach workload run ycsb" | grep -v grep | awk '{print $2}')

# Calculate the number of hosts based on the number of node PIDs
NUM_HOSTS=$(echo "${NODE_PIDS}" | wc -w)

echo $NODE_PIDS
echo $NUM_HOSTS
# Shut down each node gracefully
for PID in ${NODE_PIDS}; do
  if ! shutdown_cockroach ${PID}; then
    echo "Proceeding to the next node despite the failure."
  fi
done

echo "cockroach down"

sleep 5

rm -rf /users/Khombal2/node1/cockroach-temp*
rm -rf /users/Khombal2/node2/cockroach-temp*
rm -rf /users/Khombal2/node3/cockroach-temp*

./cluster.sh $1
