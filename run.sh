#!/usr/bin/env bash

path="/spare/thodp/myfio/sanity_check/fio_thread_4/sith2_nvme0n1"

device="nvme0n1"
block_sizes=(1 4 16 24 32 64 128 256)
iodepths=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24)
numjobs=4
echo "==========================================================="
echo "Numjobs: $numjobs"
echo

STARTTIME=$(date +%s)

for bs in ${block_sizes[@]}; do
	for io in ${iodepths[@]}; do
		echo -n "Request: ${bs}KB IOdepth: ${io}"
		echo
		mkdir -p "$path/seqreads/iodepth_$io/request_size_$bs/"
		#mkdir -p "$path/seqwrites/iodepth_$io/request_size_$bs/"
		#mkdir -p "$path/randreads/iodepth_$io/request_size_$bs/"
		#mkdir -p "$path/randwrites/iodepth_$io/request_size_$bs/"

		#BLOCK_SIZE="${bs}k" SIZE='50%' DEVICE="$device" IODEPTH="$io" NJOBS="$numjobs" fio scripts/rand-write.fio --output="$path/randwrites/iodepth_${io}/request_size_${bs}/fio_out.txt"	
		echo
		#BLOCK_SIZE="${bs}k" SIZE='50%' DEVICE="$device" IODEPTH="$io" NJOBS="$numjobs" fio scripts/rand-read.fio --output="$path/randreads/iodepth_${io}/request_size_${bs}/fio_out.txt"	
		echo
		#BLOCK_SIZE="${bs}k" SIZE='50%' DEVICE="$device" IODEPTH="$io" NJOBS="$numjobs" fio scripts/write.fio --output="$path/seqwrites/iodepth_${io}/request_size_${bs}/fio_out.txt"
		echo
		BLOCK_SIZE="${bs}k" SIZE='50%' DEVICE="$device" IODEPTH="$io" NJOBS="$numjobs" fio scripts/read.fio --output="$path/seqreads/iodepth_${io}/request_size_${bs}/fio_out.txt"
		echo
	done
done
for bs in ${block_sizes[@]}; do
        for io in ${iodepths[@]}; do
		python3 parse.py "$path/seqreads/iodepth_${io}/request_size_${bs}/fio_out.txt" "$path/seqreads/iodepth_${io}" ${bs}
		#python3 parse.py "$path/seqwrites/iodepth_${io}/request_size_${bs}/fio_out.txt" "$path/seqwrites/iodepth_${io}" ${bs}
		#python3 parse.py "$path/randreads/iodepth_${io}/request_size_${bs}/fio_out.txt" "$path/randreads/iodepth_${io}" ${bs}
		#python3 parse.py "$path/randwrites/iodepth_${io}/request_size_${bs}/fio_out.txt" "$path/randwrites/iodepth_${io}" ${bs}
	done
done
python3 plot.py "$path/seqreads" "$path" "${iodepths[@]}" "seq_reads" throughput
python3 plot.py "$path/seqreads" "$path" "${iodepths[@]}" "seq_reads_usage" cpu
#python3 plot.py "$path/seqwrites" "$path" "${iodepths[@]}" "seq_writes" throughput
#python3 plot.py "$path/seqwrites" "$path" "${iodepths[@]}" "seq_writes_usage" cpu
#python3 plot.py "$path/randreads" "$path" "${iodepths[@]}" "rand_reads" throughput
#python3 plot.py "$path/randreads" "$path" "${iodepths[@]}" "rand_reads_usage" cpu
#python3 plot.py "$path/randwrites" "$path" "${iodepths[@]}" "rand_writes" throughput
#python3 plot.py "$path/randwrites" "$path" "${iodepths[@]}" "rand_writes_usage" cpu

ENDTIME=$(date +%s)
ELAPSEDTIME=$(($ENDTIME - $STARTTIME))
FORMATED="$(($ELAPSEDTIME / 3600))h:$(($ELAPSEDTIME % 3600 / 60))m:$(($ELAPSEDTIME % 60))s"

echo
echo
echo "  Overall time elapsed: $FORMATED"
echo "==========================================================="
echo
