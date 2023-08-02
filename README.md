# BenchmarkFIO
Scripts for bench-marking a block device using FIO and then plotting results.
## Prequisites
- FIO
- python3+
- matplotlib
## Usage
change from **run.sh**

**path="/spare/thodp/myfio/sanity_check/fio_thread_4/sith2_nvme0n1"**<br>
**device="nvme0n1"**<br>
**block_sizes=(1 4 16 24 32 64 128 256)**<br>
**iodepths=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24)**<br>
**numjobs=4**<br>

and RUN: **./run.sh**

**IF** you want to benchmark an exported block device between a **client** and a **server** use **sshrun.sh**
and change:

**path="/home1/public/thodp/test_fio/FIO-scripts/out/fio_thread_16/sith2_nvme0n1"<br>
hostname="sith2"**
the above from **run.sh**

and RUN: **./sshrun.sh**
