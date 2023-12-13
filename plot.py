import argparse
from pathlib import Path
import matplotlib.pyplot as plt
from collections import defaultdict
from itertools import combinations
miss_data = {}
load = []
a = []
b = []
c = []
d = []
f = []
def process_cache_dir(cache_dir, workload_name):
    workload_dir = cache_dir / 'keys' / workload_name
    if not workload_dir.exists() or len(list(workload_dir.glob('node[1-3].txt'))) <= 2:
        return None

    datas = {}
    tmp = {}
    for node_file in workload_dir.glob('node[1-3].txt'):
        with open(node_file, 'r') as n:
            data = set(line.strip() for line in n)
            datas[node_file.stem] = data  # Save data with node name as key

    for miss in workload_dir.glob('hit_miss_rates.txt'):
        with open(miss, 'r') as m:
            data = int(str(m.readlines()).split(" ")[5].split("\\")[0])
            p_dir = str(miss.parents[0]).split("/")
            tmp[p_dir[2]] = data
            match p_dir[4]:
                case "a":
                    a.append(tmp)
                case "b":
                    b.append(tmp)
                case "c":
                    c.append(tmp)
                case "d":
                    d.append(tmp)
                case "f":
                    f.append(tmp)
                case "load":
                    load.append(tmp)
    miss_data["a"] = a
    miss_data["b"] = b
    miss_data["c"] = c
    miss_data["d"] = d
    miss_data["f"] = f
    miss_data["load"] = load

    return datas

def plot_miss_rate(results_folder, total_dataset_keys):
    for workload_name, datasets in miss_data.items():
        keys = [float(list(data.keys())[0]) for data in datasets]
        values = [list(data.values())[0] for data in datasets]
        # print(values)
        for i in range(len(values)):
            values[i] = values[i] / int(total_dataset_keys)
        # print(values)

        # Sorting the data by keys to make the plot readable
        sorted_pairs = sorted(zip(keys, values))
        keys, values = zip(*sorted_pairs)

        # Create a plot
        plt.figure(figsize=(10, 6))
        plt.plot(keys, values, marker='o')  # You can customize the plot with different markers, colors, etc.
        plt.title(f'Workload: {workload_name}')
        plt.xlabel('cache_size')
        plt.ylabel('missrate')
        plt.grid(True)
        plt.savefig(results_folder / f'{workload_name}_miss_rate.png')
        plt.show()

def calculate_metrics(datas, total_dataset_keys):
    if not datas:
        return {}

    metrics = {}
    for r in range(2, len(datas) + 1):  # Process combinations of two or more nodes
        for subset in combinations(datas.items(), r):
            subset_keys = [node for node, _ in subset]
            subset_data = [data for _, data in subset]

            total_keys = sum(len(d) for d in subset_data)
            unique_keys = len(set.union(*subset_data))
            common_keys = len(set.intersection(*subset_data))
            average_num_keys = int(total_keys / len(subset_data))
            cache_ratio = average_num_keys / total_dataset_keys
            csf = common_keys / average_num_keys if average_num_keys else 0
            cef = unique_keys / total_dataset_keys if total_dataset_keys else 0

            metrics[f'{subset_keys}'] = {
                'total_keys': total_keys,
                'unique_keys': unique_keys,
                'common_keys': common_keys,
                'average_num_keys': average_num_keys,
                'cache_ratio': round(cache_ratio, 3),
                'csf': round(csf, 3),
                'cef': round(cef, 3)
            }

    return metrics

def process_run(run_dir, total_dataset_keys):
    workloads = defaultdict(dict)
    for cache_dir in run_dir.iterdir():
        if cache_dir.is_dir() and cache_dir.name.replace('.', '', 1).isdigit():
            for workload_name in ['a', 'b', 'c', 'd', 'f', 'load']:
                datas = process_cache_dir(cache_dir, workload_name)
                if datas:
                    workloads[workload_name][cache_dir.name] = calculate_metrics(datas, total_dataset_keys)
    return workloads

def plot_metrics(workloads, results_folder):

    for workload_name, datasets in workloads.items():
        print(f'Workload: {workload_name}')
        print('===========================')
        all_csfs = []
        all_cefs = []
        all_cache_ratios = []

        for cache_size, metrics in datasets.items():
            if not metrics:
                continue

            print(f'Cache Size: {cache_size}')
            for combo, metric in metrics.items():
                combo_list = combo.strip('[]').split(', ')
                print(f'{combo} - Metrics: {metric}')  # Print metrics for each combination
                if len(combo_list) == 3:  # Process only three-node combinations
                    all_cache_ratios.append(metric['cache_ratio'])
                    all_csfs.append(metric['csf'])
                    all_cefs.append(metric['cef'])

            print('----------------------------')

        # Sort data points by cache ratio
        sorted_data = sorted(zip(all_cache_ratios, all_csfs, all_cefs))
        sorted_ratios, sorted_csfs, sorted_cefs = zip(*sorted_data)

        # print(sorted_data)
        # Plot CSF for all data points with lines
        plt.figure(figsize=(10, 6))
        plt.plot(sorted_ratios, sorted_csfs, color='blue', marker='o', linestyle='-', label='CSF')
        plt.xlabel('Cache Ratio (Average Keys / Total Keys)')
        plt.ylabel('CSF')
        plt.ylim(0.0, 1.0)
        plt.title(f'CSF for Workload {workload_name}')
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(results_folder / f'{workload_name}_CSF.png')
        plt.close()

        # Plot CEF for all data points with lines
        plt.figure(figsize=(10, 6))
        plt.plot(sorted_ratios, sorted_cefs, color='red', marker='o', linestyle='-', label='CEF')
        plt.xlabel('Cache Ratio (Average Keys / Total Keys)')
        plt.ylabel('CEF')
        plt.ylim(0.0, 1.0)
        plt.title(f'CEF for Workload {workload_name}')
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(results_folder / f'{workload_name}_CEF.png')
        plt.close()

        print('===========================')



def main():
    parser = argparse.ArgumentParser(description='Process cache directories and plot metrics.')
    parser.add_argument('run_dir', type=str, help='Path to the run directory')
    parser.add_argument('results_folder', type=str, help='Path to save results')
    parser.add_argument('total_dataset_keys', type=int, help='Total number of dataset keys')

    args = parser.parse_args()

    run_dir = Path(args.run_dir)
    results_folder = Path(args.results_folder)
    total_dataset_keys = args.total_dataset_keys

    results_folder.mkdir(exist_ok=True)
    workloads = process_run(run_dir, total_dataset_keys)
    plot_miss_rate(results_folder, total_dataset_keys)
    plot_metrics(workloads, results_folder)

if __name__ == "__main__":
    main()

