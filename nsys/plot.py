#!/usr/bin/env python3
"""
Plot GPU memory-usage from two log formats on the same time axis.

file 1: "<ns_since_launch> <bytes>\n"
file 2: "YYYY/MM/DD HH:MM:SS.mmm <megabytes>\n"
"""

import argparse
from pathlib import Path
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib.ticker as tck

def parse_ns_bytes(path: Path):
    """Return (t_seconds, mem_gib) lists from <ns> <bytes> file."""
    t_sec, mem_gib_total, mem_gib_valid, mem_gib_driver, mem_gib_notfound = [], [], [], [], []
    with path.open() as f:
        for line in f:
            if not line.strip():
                continue
            if "time" in line:
                continue
            ns, bytes_total, bytes_valid, bytes_notfound, bytes_driver = map(int, line.split())
            t_sec.append(ns / 1e9)
            mem_gib_total.append(bytes_total / 1024**3)
            mem_gib_valid.append(bytes_valid / 1024**3)
            mem_gib_notfound.append(bytes_notfound / 1024**3)
            mem_gib_driver.append(bytes_driver / 1024**3)
    return t_sec, mem_gib_total, mem_gib_valid, mem_gib_driver, mem_gib_notfound


def parse_datetime_mb(path: Path):
    """Return (t_seconds, mem_gib) lists from timestamp+MB file."""
    t_abs, mem_gib = [], []
    prev_mb = -1
    with path.open() as f:
        for line in f:
            if not line.strip():
                continue
            ts_str, mb = line.rsplit(maxsplit=1)
            if prev_mb != -1 and mb != prev_mb:
                # 2025/06/22 23:15:07.123  -> datetime
                t_abs.append(
                    datetime.strptime(ts_str, "%Y/%m/%d %H:%M:%S.%f,").timestamp()
                )
                mem_gib.append(float(mb) / 1024)
            prev_mb = mb
    if not t_abs:
        return [], []
    # convert absolute → relative seconds
    t0 = t_abs[0]
    t_sec = [t - t0 for t in t_abs]
    return t_sec, mem_gib


# ----------------------------------------------------------------------
def main():
    p = argparse.ArgumentParser()
    p.add_argument("-u", "--usage", type=Path, nargs="+", help="profile usage logs", required=False)
    p.add_argument("-s", "--smi", type=Path, nargs="+", help="nvidia-smi memory usage logs", required=False)
    p.add_argument("-o", "--output", type=Path, help="Output png file path", required=True)
    args = p.parse_args()

    u_timestamps, u_totals, u_valids, u_drivers, u_invalids = [], [], [], [], []
    if not args.usage and not args.smi:
        print("No input files specified. Use -h for help.")
        return
    if args.usage:
        for p in args.usage:
            u_timestamp, u_total, u_valid, u_driver, u_invalid = parse_ns_bytes(p)
            u_timestamps.append(u_timestamp)
            u_totals.append(u_total)
            u_valids.append(u_valid)
            u_drivers.append(u_driver)
            u_invalids.append(u_invalid)
    s_timestamps, s_totals = [], []
    if args.smi:
        for p in args.smi:
            s_timestamp, s_total = parse_datetime_mb(p)
            s_timestamps.append(s_timestamp)
            s_totals.append(s_total)

    minimum_timestamp = float("inf")
    maximum_total = float("-inf")
    for p in u_timestamps:
        for t in p:
            minimum_timestamp = min(minimum_timestamp, t)
    for p in s_timestamps:
        for t in p:
            minimum_timestamp = min(minimum_timestamp, t)
    for p_id in range(len(u_timestamps)):
        for t_id in range(len(u_timestamps[p_id])):
            u_timestamps[p_id][t_id] -= minimum_timestamp
            maximum_total = max(maximum_total, u_totals[p_id][t_id])
    for p_id in range(len(s_timestamps)):
        for t_id in range(len(s_timestamps[p_id])):
            s_timestamps[p_id][t_id] -= minimum_timestamp
            maximum_total = max(maximum_total, s_totals[p_id][t_id])
    
    maximum_total = (maximum_total // 10 + 1) * 10  # round up to next multiple of 10

    for p_id in range(len(u_timestamps)):
        plt.plot(u_timestamps[p_id], u_totals[p_id], label=f"prof_{p_id} (total)")
        plt.plot(u_timestamps[p_id], u_valids[p_id], label=f"prof_{p_id} (valid)")
        plt.plot(u_timestamps[p_id], u_drivers[p_id], label=f"prof_{p_id} (driver)")
        plt.plot(u_timestamps[p_id], u_invalids[p_id], label=f"prof_{p_id} (not found)")
    for p_id in range(len(s_timestamps)):
        plt.plot(s_timestamps[p_id], s_totals[p_id], label=f"smi_{p_id} (total)")        
    plt.xlabel("Time since process start (s)")
    plt.ylabel("Memory usage (GiB)")

    plt.gca().yaxis.set_major_locator(tck.MultipleLocator(10))
    plt.gca().set_ylim(0, maximum_total)
    plt.gca().grid(axis="y")

    plt.gca().xaxis.set_major_locator(tck.MultipleLocator(25))
    plt.title("GPU memory usage")
    plt.legend()
    plt.tight_layout()

    if args.output:
        plt.savefig(args.output, dpi=180)
        print(f"saved → {args.output}")
    else:
        plt.show()

if __name__ == "__main__":
    main()