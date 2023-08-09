#!/usr/bin/env bash

server="/home1/public/thodp/test_fio/BenchmarkFIO/out/fio_thread_4/networktest"
client="/spare/thodp/BenchmarkFIO/out/fio_thread_4/networktest"
hostname="sith2"
interface="ens10d1"

device="nbd0"
block_sizes=(64 128 256)
iodepths=(8)
numjobs=4

ssh thodp@"$hostname" "mkdir -p $server"

rm -rf "$client/*"

output=$(ethtool -S ens10d1)

rx_packets=$(echo "$output" | grep -oE 'rx_packets: [0-9]+' | awk '{print $2}')
tx_packets=$(echo "$output" | grep -oE 'tx_packets: [0-9]+' | awk '{print $2}')

rx_bytes=$(echo "$output" | grep -oE 'rx_bytes: [0-9]+' | awk '{print $2}')
tx_bytes=$(echo "$output" | grep -oE 'tx_bytes: [0-9]+' | awk '{print $2}')

echo "==========================================================="
echo "Numjobs: $numjobs"
echo

ssh thodp@"$hostname" "mpstat 1 > $server/tempssh.txt" &
sleep 3
mpstat_pid_ssh=$(ssh thodp@sith2 pgrep -o mpstat)

tshark -i "$interface" tcp -w "$client/pack.pcap" &
tshark_pid=$!

STARTTIME=$(date +%s)

for bs in ${block_sizes[@]}; do
        for io in ${iodepths[@]}; do
                echo -n "Request: ${bs}KB IOdepth: ${io}"
                echo
                mkdir -p "$client/seqreads/iodepth_$io/request_size_$bs/"
                mkdir -p "$client/seqwrites/iodepth_$io/request_size_$bs/"
                mkdir -p "$client/randreads/iodepth_$io/request_size_$bs/"
                mkdir -p "$client/randwrites/iodepth_$io/request_size_$bs/"
                
		#BLOCK_SIZE="${bs}k" SIZE='50%' DEVICE="$device" IODEPTH="$io" NJOBS="$numjobs" fio scripts/rand-write.fio --output="$client/randwrites/iodepth_${io}/request_size_${bs}/fio_out.txt"      
                echo
                #BLOCK_SIZE="${bs}k" SIZE='50%' DEVICE="$device" IODEPTH="$io" NJOBS="$numjobs" fio scripts/rand-read.fio --output="$client/randreads/iodepth_${io}/request_size_${bs}/fio_out.txt"        
                echo
                #BLOCK_SIZE="${bs}k" SIZE='50%' DEVICE="$device" IODEPTH="$io" NJOBS="$numjobs" fio scripts/write.fio --output="$client/seqwrites/iodepth_${io}/request_size_${bs}/fio_out.txt"
                echo
                BLOCK_SIZE="${bs}k" SIZE='10G' DEVICE="$device" IODEPTH="$io" NJOBS="$numjobs" fio scripts/read.fio --output="$client/seqreads/iodepth_${io}/request_size_${bs}/fio_out.txt"
                echo
        done
done

kill "$tshark_pid"
tshark -r "$client/pack.pcap" -q -z io,phs > "$client/proto_hierarchy.txt"
tshark -qz plen,tree -r "$client/pack.pcap" > "$client/pack_lengths.txt"

for bs in ${block_sizes[@]}; do
        for io in ${iodepths[@]}; do
                python3 parse.py "$client/seqreads/iodepth_${io}/request_size_${bs}/fio_out.txt" "$client/seqreads/iodepth_${io}" ${bs}
                python3 parse.py "$client/seqwrites/iodepth_${io}/request_size_${bs}/fio_out.txt" "$client/seqwrites/iodepth_${io}" ${bs}
                python3 parse.py "$client/randreads/iodepth_${io}/request_size_${bs}/fio_out.txt" "$client/randreads/iodepth_${io}" ${bs}
                python3 parse.py "$client/randwrites/iodepth_${io}/request_size_${bs}/fio_out.txt" "$client/randwrites/iodepth_${io}" ${bs}
        done
done
python3 plot.py "$client/seqreads" "$client" "${iodepths[@]}" "seq_reads" throughput
python3 plot.py "$client/seqreads" "$client" "${iodepths[@]}" "seq_reads_usage" cpu
python3 plot.py "$client/seqwrites" "$client" "${iodepths[@]}" "seq_writes" throughput
python3 plot.py "$client/seqwrites" "$client" "${iodepths[@]}" "seq_writes_usage" cpu
python3 plot.py "$client/randreads" "$client" "${iodepths[@]}" "rand_reads" throughput
python3 plot.py "$client/randreads" "$client" "${iodepths[@]}" "rand_reads_usage" cpu
python3 plot.py "$client/randwrites" "$client" "${iodepths[@]}" "rand_writes" throughput
python3 plot.py "$client/randwrites" "$client" "${iodepths[@]}" "rand_writes_usage" cpu

ENDTIME=$(date +%s)
ELAPSEDTIME=$(($ENDTIME - $STARTTIME))
FORMATED="$(($ELAPSEDTIME / 3600))h:$(($ELAPSEDTIME % 3600 / 60))m:$(($ELAPSEDTIME % 60))s"

echo
echo
echo "  Overall time elapsed: $FORMATED"
echo "==========================================================="
echo

output2=$(ethtool -S ens10d1)

rx_packets2=$(echo "$output2" | grep -oE 'rx_packets: [0-9]+' | awk '{print $2}')
tx_packets2=$(echo "$output2" | grep -oE 'tx_packets: [0-9]+' | awk '{print $2}')

rx_bytes2=$(echo "$output2" | grep -oE 'rx_bytes: [0-9]+' | awk '{print $2}')  
tx_bytes2=$(echo "$output2" | grep -oE 'tx_bytes: [0-9]+' | awk '{print $2}')

total_rx_packets=$((rx_packets2-rx_packets))
total_tx_packets=$((tx_packets2-tx_packets))

total_rx_bytes=$((rx_bytes2-rx_bytes))
total_tx_bytes=$((tx_bytes2-tx_bytes))

echo "total_rx_packets: $total_rx_packets" > "$client/rx_tx.txt"
echo "total_tx_packets: $total_tx_packets" >> "$client/rx_tx.txt"
echo "total_rx_bytes: $total_rx_bytes" >> "$client/rx_tx.txt"
echo "total_tx_bytes: $total_tx_bytes" >> "$client/rx_tx.txt"

echo "KILL pidstat processes and create cpu utilization file"
ssh thodp@"$hostname" "kill $mpstat_pid_ssh"

head -n -2 "$server/tempssh.txt" | awk 'BEGIN{OFS=";"} NR>3 && !/^Average:/ {print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13}' > "$client/cpu_utilssh.txt"
rm -rf "$server/tempssh.txt"
python3 calculate_averages.py "$client/cpu_utilssh.txt" "$client/cpu_avgssh.txt"
