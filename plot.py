import os
import argparse
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import numpy as np
import glob

def read_values(file_path):
    with open(file_path, 'r') as infile:
        lines = infile.readlines()
        values, request_size_values = zip(*[map(float, line.strip().split(',')) for line in lines])
        return values, request_size_values

def plot_metric(input_path, output_path, iodepths, plot_name, metric_name):
    plt.figure(figsize=(10, 6))

    colormap = cm.rainbow(np.linspace(0, 1, len(iodepths)))  # Generate colors based on the number of iodepths
    color_mapping = dict(zip(iodepths, colormap))

    all_metric_values = []
    all_metric_labels = []
    x_ticks_positions = []

    for iodepth in iodepths:
        iodepth_dir = os.path.join(input_path, f"iodepth_{iodepth}")
        files = glob.glob(os.path.join(iodepth_dir, f"{metric_name}.txt"))

        metric_values, request_size_values = [], []
        for file in files:
            m_values, r_values = read_values(file)
            metric_values.extend(m_values)
            request_size_values.extend(r_values)

        all_metric_values.extend(metric_values)
        all_metric_labels.extend(request_size_values)

        color = color_mapping[iodepth]  # Assign a color to the current iodepth
        plt.plot(request_size_values, metric_values, label=f"IODEPTH={iodepth}", color=color)

        # Add markers at the points where the request size changes
        for i in range(1, len(request_size_values)):
            if request_size_values[i] != request_size_values[i - 1]:
                plt.scatter(request_size_values[i], metric_values[i], color=color)

    plt.xlabel("Request Size (KB)")
    plt.ylabel("Throughput (MB/s)" if metric_name == "throughput" else "CPU %")
    plt.title(plot_name)
    plt.legend(loc="best")

    # Set the x-axis ticks and labels to the exact request sizes from the data
    plt.xticks(request_size_values, rotation=45)

    # Save the plot as an EPS file
    eps_file_path = os.path.join(output_path, f"{plot_name}.eps")
    plt.savefig(eps_file_path)
    plt.show()

def main():
    parser = argparse.ArgumentParser(description="Plot throughput or CPU usage from FIO output files.")
    parser.add_argument("input_path", help="Path to input directory containing FIO output files.")
    parser.add_argument("output_path", help="Path to output directory to save the plot.")
    parser.add_argument("iodepths", nargs="+", type=int, help="List of iodepth values.")
    parser.add_argument("plot_name", help="Name for the plot and EPS file.")
    parser.add_argument("metric_name", choices=["throughput", "cpu"], help="Metric to plot (throughput or cpu usage).")

    args = parser.parse_args()
    plot_metric(args.input_path, args.output_path, args.iodepths, args.plot_name, args.metric_name)

if __name__ == "__main__":
    main()

