import os
import csv
import re
import math

def extract_values(input_file, request_size):
    bw_value = 0
    usr_value = 0
    sys_value = 0

    with open(input_file, 'r') as infile:
        for line in infile:
            bw_match = re.search(r'bw=(\d+(\.\d+)?)MiB/s', line)
            if bw_match:
                bw_value = float(bw_match.group(1))

            usr_match = re.search(r'usr=(\d+(\.\d+)?)%', line)
            if usr_match:
                usr_value = float(usr_match.group(1))

            sys_match = re.search(r'sys=(\d+(\.\d+)?)%', line)
            if sys_match:
                sys_value = float(sys_match.group(1))

            if bw_value and usr_value and sys_value:
                break  # Stop searching once all values are found

    # Convert BW value to MB/s and round up
    bw_value_mb = math.ceil(bw_value * 1.04858)
    cpu_usage = int(round(usr_value + sys_value))
    return bw_value_mb, cpu_usage, request_size

def main():
    import sys

    if len(sys.argv) != 4:
        print("Usage: python parse.py input_file.txt output_directory_path block_size")
        sys.exit(1)

    input_file = sys.argv[1]   # Get the first command-line argument as the input file name
    output_directory = sys.argv[2]  # Get the second command-line argument as the output directory path
    request_size = int(sys.argv[3])  # Get the third command-line argument as the request size (block size)

    bw_value_mb, cpu_usage, _ = extract_values(input_file, request_size)

    # Write the throughput values to out.txt
    out_file_path = os.path.join(output_directory, "throughput.txt")
    with open(out_file_path, 'a', newline='') as out_file:
        csv_writer = csv.writer(out_file)
        csv_writer.writerow([bw_value_mb, request_size])

    # Write the CPU usage values to usage.txt
    usage_file_path = os.path.join(output_directory, "cpu.txt")
    with open(usage_file_path, 'a', newline='') as usage_file:
        csv_writer = csv.writer(usage_file)
        csv_writer.writerow([cpu_usage, request_size])

if __name__ == "__main__":
    main()

