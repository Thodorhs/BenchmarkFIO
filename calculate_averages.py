#!/usr/bin/env python3

import sys

def calculate_averages(input_file, output_file):
    column_sums = [0] * 10
    avg = [0] * 10
    row_count = 0

    with open(input_file, 'r') as f:
        for line in f:
            row = [float(val.replace(',', '.')) for val in line.strip().split(';')[1:]]
            for i in range(10):
                column_sums[i] += row[i]
            row_count += 1
    with open(output_file, 'w') as out_f:
        out_f.write("avg-cpu:  %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle\n")
        out_f.write("        ")
        i = 0
        for col_sum in column_sums:
            avg[i] = col_sum / row_count
            out_f.write(f"  {avg[i]:.2f} ")
            i += 1

        cpu_time = 100 - avg[4] - avg[9]  # Exclude the "irq" column
        out_f.write(f"\ncpu_time: {cpu_time:.2f}\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python calculate_averages.py input_file output_file")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    calculate_averages(input_file, output_file)
