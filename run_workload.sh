#!/bin/bash

export BASE_DIR="/users/Khombal2/logsDump"
export WORKING_DIR=""
export run_number=1
export trigger="/users/Khombal2/cockroach/trigger"
export dump="/users/Khombal2/cockroach/dump"

# Configuration parameters
NUM_HOSTS=3
NUM_OF_KEYS=1000000
NUM_OF_OPS_PER_KEY=1
NUM_OF_OPS=$((NUM_OF_KEYS * NUM_OF_OPS_PER_KEY))
DATA_DISTRIBUTION=uniform

# declare -a cache_sizes=(0.25 0.5 0.75 1.0 1.25 1.50 1.75)
declare -a cache_sizes=(0.25)
declare -a workloads=("c")
# declare -a workloads=("a" "b" "c" "d" "f")

while [ -d "$BASE_DIR/run$run_number" ]; do
  let run_number++
done


delete_dump() {
  echo "deleting data"
  file_pattern="[0-9]{4,}$"
  find "$BASE_DIR/run$run_number" -type d -regextype posix-extended -regex ".*/$file_pattern" -exec echo "Deleting directory: {}" \; -exec sudo rm -rf {} \;
}

# Function to remove dump and create a trigger
trigger_dump() {
  delete_dump
  echo "Starting trigger_dump function"
  sudo chmod 777 -R $BASE_DIR/*
  ./cockroach workload run ycsb --workload a --max-rate 1 --insert-count 1 --duration 1s --concurrency 1 > /dev/null 2>&1
  sleep 5
  sudo touch $trigger
  sudo chmod 777 $trigger
  sudo echo "test" > $trigger
  echo "Trigger created"
  sleep 10
  echo "Slept for 10 seconds"
  ./cockroach workload run ycsb --workload a --max-rate 1 --insert-count 1 --duration 1s --concurrency 1 > /dev/null 2>&1
  sleep 10
  echo "Slept for 10 seconds"
  
  local dump_count
  while : ; do
    dump_count=$(find "$WORKING_DIR/../" -name 'cachedump.txt' | wc -l)
    echo "$dump_count of 3 data dumps found in $WORKING_DIR/"
    if [ $dump_count -lt $NUM_HOSTS ]; then
      ./cockroach workload run ycsb --workload f --max-rate 1 --insert-count 1 --duration 1s --concurrency 1 > /dev/null 2>&1
      sleep 10
      ./cockroach workload run ycsb --workload c --max-rate 1 --insert-count 1 --duration 1s --concurrency 1 > /dev/null 2>&1
      echo "Waiting for data dumps. sleeping for 10 seconds."
      sleep 10
    else
      break
    fi
  done

  sudo rm $trigger
  echo "Trigger removed. Exiting trigger_dump function."
}

# Function to clear logs and run analysis
analyze() {
  echo "Starting analyze function on $1"
  local input_string="$1"
  local node_count=1
  local output_base_dir="$WORKING_DIR/keys/$input_string"
  sudo mkdir -m 777 -p "$output_base_dir"
  echo "Output base directory created at $output_base_dir"

  for dump_dir in "$WORKING_DIR"/../*; do
    if [[ -d $dump_dir ]]; then
      for dump_file in "$dump_dir"/cachedump.txt; do
        if [[ -f $dump_file ]]; then
          sudo python3 $BASE_DIR/../match.py "$dump_file" > "${output_base_dir}/node${node_count}.txt"
          echo "Analysis completed for $dump_file"
          ((node_count++))
        fi
      done
    fi
  done
  echo "Exiting analyze function."
}

# # Navigate to the cockroach directory and build
build_code() {
  cd cockroach || { echo "Failed to enter cockroach directory"; exit 1; }
  ./dev build
  cd .. || { echo "Failed to return to the parent directory"; exit 1; }
}

# Prepare environment
env_prep() {
  cd /users/Khombal2/
  sudo mkdir -m 777 -p /users/Khombal2/results/keys
  sudo mkdir -m 777 -p $BASE_DIR
  WORKING_DIR=$BASE_DIR/run$run_number/$1
  sudo mkdir -m 777 -p $WORKING_DIR
  sudo ./cleanup.sh
  delete_dump
  sudo ./cluster.sh $1 $NUM_HOSTS
}

sudo ./cleanup.sh
build_code

sudo rm -rf $trigger
sudo rm -rf $dump

for cache_size in "${cache_sizes[@]}"; do
  echo "Printing cache size $cache_size"
  env_prep $cache_size

  cd /users/Khombal2/cockroach/
  sudo touch $dump
  sudo chmod 777 $dump
  sudo echo "test" > $dump

  # sleep 30

  ./cockroach workload init ycsb --insert-count "$NUM_OF_KEYS" --request-distribution "$DATA_DISTRIBUTION"

  sudo rm -rf $dump
  sleep 10

  # Call trigger_dump function
  trigger_dump
  sleep 30
  analyze "load"

  # Run workloads and analyze logs after each
  for workload in "${workloads[@]}"; do
    sudo touch $dump
    sudo chmod 777 $dump
    sudo echo "test" > $dump
    sleep 10
    ./cockroach workload run ycsb --workload "$workload" --max-ops "$NUM_OF_OPS" --request-distribution "$DATA_DISTRIBUTION" --duration 120s
    sleep 10
    echo rm -rf $dump
    trigger_dump
    sleep 10
    analyze $workload
  done
done
echo "Workload processing complete."
