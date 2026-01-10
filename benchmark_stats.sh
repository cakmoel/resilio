#!/bin/bash
BASE_DIR="/var/www/html/load-tester"
source /var/www/html/load-tester/lib/stats.sh

# Generate 1000 test values
declare -a data1
declare -a data2
for i in {1..1000}; do
    data1+=("$RANDOM")
    data2+=("$RANDOM")
done

echo "Benchmarking calculate_mean with 1000 items..."
time calculate_mean data1 > /dev/null

echo "Benchmarking mann_whitney_u_test with 1000x1000 items..."
echo "(This might take a while if it's truly O(n^2) with bc calls)"
time mann_whitney_u_test data1 data2 > /dev/null
