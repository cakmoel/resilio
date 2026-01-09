import pandas as pd
import matplotlib.pyplot as plt
import os
import glob
import sys

def generate_charts(report_dir):
    # Find all result CSVs
    csv_files = glob.glob(os.path.join(report_dir, "results_*.csv"))
    
    if not csv_files:
        print(f"No CSV files found in {report_dir}")
        return

    data = []
    for f in csv_files:
        scenario = os.path.basename(f).replace("results_", "").replace(".csv", "")
        df = pd.read_csv(f)
        if not df.empty:
            avg_rps = df['rps'].mean()
            p95_latency = df['p95'].mean()
            data.append({'Scenario': scenario, 'Avg RPS': avg_rps, 'P95 Latency (ms)': p95_latency})

    results_df = pd.DataFrame(data)
    
    # Plot RPS
    plt.figure(figsize=(10, 6))
    plt.bar(results_df['Scenario'], results_df['Avg RPS'], color='skyblue')
    plt.title('October CMS Performance: Average Requests Per Second')
    plt.ylabel('RPS')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.savefig(os.path.join(report_dir, 'rps_comparison.png'))
    print(f"Created rps_comparison.png in {report_dir}")
    
    # Plot Latency
    plt.figure(figsize=(10, 6))
    plt.bar(results_df['Scenario'], results_df['P95 Latency (ms)'], color='salmon')
    plt.title('October CMS Performance: P95 Latency (ms)')
    plt.ylabel('Latency (ms)')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.savefig(os.path.join(report_dir, 'latency_comparison.png'))
    print(f"Created latency_comparison.png in {report_dir}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        generate_charts(sys.argv[1])
    else:
        print("Usage: python3 visualize_results.py <report_directory>")
