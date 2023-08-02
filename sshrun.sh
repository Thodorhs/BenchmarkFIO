#!/usr/bin/env bash

path="/home1/public/thodp/test_fio/FIO-scripts/out/fio_thread_16/sith2_nvme0n1"
hostname="sith2"

ssh thodp@"$hostname" "mpstat 1 > /home1/public/thodp/test_fio/FIO-scripts/out/fio_thread_16/sith2_nvme0n1/tempssh.txt" &
sleep 3
mpstat_pid_ssh=$(ssh thodp@sith2 pgrep -o mpstat)

output=$(ethtool -S ens10d1)

rx_packets=$(echo "$output" | grep -oE 'rx_packets: [0-9]+' | awk '{print $2}')
tx_packets=$(echo "$output" | grep -oE 'tx_packets: [0-9]+' | awk '{print $2}')

rx_bytes=$(echo "$output" | grep -oE 'rx_bytes: [0-9]+' | awk '{print $2}')
tx_bytes=$(echo "$output" | grep -oE 'tx_bytes: [0-9]+' | awk '{print $2}')

./run.sh &
fio_run=$!

wait $fio_run
sleep 5

output2=$(ethtool -S ens10d1)

rx_packets2=$(echo "$output2" | grep -oE 'rx_packets: [0-9]+' | awk '{print $2}')
tx_packets2=$(echo "$output2" | grep -oE 'tx_packets: [0-9]+' | awk '{print $2}')

rx_bytes2=$(echo "$output2" | grep -oE 'rx_bytes: [0-9]+' | awk '{print $2}')  
tx_bytes2=$(echo "$output2" | grep -oE 'tx_bytes: [0-9]+' | awk '{print $2}')

total_rx_packets=$((rx_packets2-rx_packets))
total_tx_packets=$((tx_packets2-tx_packets))

total_rx_bytes=$((rx_bytes2-rx_bytes))
total_tx_bytes=$((tx_bytes2-tx_bytes))

echo "total_rx_packets: $total_rx_packets" > "$path/rx_tx.txt"
echo "total_tx_packets: $total_tx_packets" >> "$path/rx_tx.txt"
echo "total_rx_bytes: $total_rx_bytes" >> "$path/rx_tx.txt"
echo "total_tx_bytes: $total_tx_bytes" >> "$path/rx_tx.txt"

echo "KILL pidstat processes and create cpu utilization file"
ssh thodp@"$hostname" "kill $mpstat_pid_ssh"
ssh thdop@"$hostname" "exit"

head -n -2 "$path/tempssh.txt" | awk 'BEGIN{OFS=";"} NR>3 && !/^Average:/ {print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13}' > "$path/cpu_utilssh.txt"
rm -f "$path/tempssh.txt"
python3 calculate_averages.py "$path/cpu_utilssh.txt" "$path/cpu_avgssh.txt"
