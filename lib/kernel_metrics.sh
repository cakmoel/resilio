#!/bin/bash
# shellcheck shell=bash
# =============================================================================
# Brendan Gregg's Kernel-Level Metrics Collection for Resilio DLT
# =============================================================================

# BASE_DIR is expected to be defined by the sourcing script (bin/dlt.sh)

# Kernel-level metrics collection
capture_kernel_metrics_data() {
    local output_file="$1"
    local timestamp
    timestamp=$(date +%s)
    
    # Process scheduling metrics (Gregg's scheduler analysis)
    local runqueue
    runqueue=$(</proc/loadavg awk '{print $2}')
    local runnable
    runnable=$(grep procs_running /proc/stat | awk '{print $2}')
    local blocked
    blocked=$(grep procs_blocked /proc/stat | awk '{print $2}')
    
    # Context switches and interrupts
    local ctxt
    ctxt=$(grep ctxt /proc/stat | awk '{print $2}')
    local intr
    intr=$(grep intr /proc/stat | awk '{print $2}')
    local softirq
    softirq=$(grep softirq /proc/stat | awk '{print $2}')
    
    # Memory subsystem metrics
    local nr_free_pages
    nr_free_pages=$(grep nr_free_pages /proc/vmstat | awk '{print $2}')
    local nr_inactive_anon
    nr_inactive_anon=$(grep nr_inactive_anon /proc/vmstat | awk '{print $2}')
    local nr_active_anon
    nr_active_anon=$(grep nr_active_anon /proc/vmstat | awk '{print $2}')
    local nr_inactive_file
    nr_inactive_file=$(grep nr_inactive_file /proc/vmstat | awk '{print $2}')
    local nr_active_file
    nr_active_file=$(grep nr_active_file /proc/vmstat | awk '{print $2}')
    local pgmajfault
    pgmajfault=$(grep pgmajfault /proc/vmstat | awk '{print $2}')
    
    # File system metrics
    local nr_dirty
    nr_dirty=$(grep nr_dirty /proc/vmstat | awk '{print $2}')
    local nr_writeback
    nr_writeback=$(grep nr_writeback /proc/vmstat | awk '{print $2}')
    
    # TCP metrics
    local tcp_active
    tcp_active=$(grep -A1 Tcp: /proc/net/snmp | tail -1 | awk '{print $9}')
    local tcp_passive
    tcp_passive=$(grep -A1 Tcp: /proc/net/snmp | tail -1 | awk '{print $10}')
    local tcp_retrans_segs
    tcp_retrans_segs=$(grep -A1 Tcp: /proc/net/snmp | tail -1 | awk '{print $12}')
    
    echo "$timestamp,$runqueue,$runnable,$blocked,$ctxt,$intr,$softirq,$nr_free_pages,$nr_inactive_anon,$nr_active_anon,$nr_inactive_file,$nr_active_file,$pgmajfault,$nr_dirty,$nr_writeback,$tcp_active,$tcp_passive,$tcp_retrans_segs" >> "$output_file"
}

# Process-level metrics (Gregg's process analysis)
capture_process_metrics() {
    local output_file="$1"
    local target_pid="$2"
    local timestamp
    timestamp=$(date +%s)
    
    if [ -z "$target_pid" ] || [ ! -d "/proc/$target_pid" ]; then
        echo "Error: Invalid PID $target_pid"
        return 1
    fi
    
    # Process CPU metrics
    local proc_utime
    proc_utime=$(</proc/"$target_pid"/stat awk '{print $14}')
    local proc_stime
    proc_stime=$(</proc/"$target_pid"/stat awk '{print $15}')
    local proc_cutime
    proc_cutime=$(</proc/"$target_pid"/stat awk '{print $16}')
    local proc_cstime
    proc_cstime=$(</proc/"$target_pid"/stat awk '{print $17}')
    local proc_threads
    proc_threads=$(</proc/"$target_pid"/stat awk '{print $20}')
    
    # Process memory metrics
    local proc_vsize
    proc_vsize=$(</proc/"$target_pid"/stat awk '{print $23}')
    local proc_rss
    proc_rss=$(</proc/"$target_pid"/stat awk '{print $24}')
    local proc_rss_anon
    proc_rss_anon=$(grep RssAnon /proc/"$target_pid"/smaps_rollup 2>/dev/null | awk '{print $2}' || echo "0")
    local proc_rss_file
    proc_rss_file=$(grep RssFile /proc/"$target_pid"/smaps_rollup 2>/dev/null | awk '{print $2}' || echo "0")
    
    # Process I/O metrics
    local read_bytes
    read_bytes=$(grep read_bytes /proc/"$target_pid"/io 2>/dev/null | awk '{print $2}' || echo "0")
    local write_bytes
    write_bytes=$(grep write_bytes /proc/"$target_pid"/io 2>/dev/null | awk '{print $2}' || echo "0")
    local read_ops
    read_ops=$(grep syscr /proc/"$target_pid"/io 2>/dev/null | awk '{print $2}' || echo "0")
    local write_ops
    write_ops=$(grep syscw /proc/"$target_pid"/io 2>/dev/null | awk '{print $2}' || echo "0")
    
    # Process file descriptors
    local fd_count
    fd_count=$(find /proc/"$target_pid"/fd 2>/dev/null | wc -l)
    
    # Context switches
    local vol_ctxt
    vol_ctxt=$(</proc/"$target_pid"/status grep voluntary_ctxt_switches | awk '{print $2}')
    local nonvol_ctxt
    nonvol_ctxt=$(</proc/"$target_pid"/status grep nonvoluntary_ctxt_switches | awk '{print $2}')
    
    echo "$timestamp,$target_pid,$proc_utime,$proc_stime,$proc_cutime,$proc_cstime,$proc_threads,$proc_vsize,$proc_rss,$proc_rss_anon,$proc_rss_file,$read_bytes,$write_bytes,$read_ops,$write_ops,$fd_count,$vol_ctxt,$nonvol_ctxt" >> "$output_file"
}

# Network stack deep dive (Gregg's network analysis)
capture_network_stack_metrics() {
    local output_file="$1"
    local timestamp
    timestamp=$(date +%s)
    
    # TCP detailed metrics
    local tcp_ext
    tcp_ext=$(</proc/net/netstat grep TcpExt: | tail -1)
    local syncookies_sent
    syncookies_sent=$(echo "$tcp_ext" | awk '{print $11}')
    local syncookies_recv
    syncookies_recv=$(echo "$tcp_ext" | awk '{print $12}')
    local syncookies_failed
    syncookies_failed=$(echo "$tcp_ext" | awk '{print $13}')
    local embryonic_rsts
    embryonic_rsts=$(echo "$tcp_ext" | awk '{print $16}')
    local prune_called
    prune_called=$(echo "$tcp_ext" | awk '{print $17}')
    
    # TCP retransmission metrics
    local tcp_retrans
    tcp_retrans=$(grep -A1 Tcp: /proc/net/snmp | tail -1)
    local tcp_retrans_segs
    tcp_retrans_segs=$(echo "$tcp_retrans" | awk '{print $12}')
    local tcp_out_segs
    tcp_out_segs=$(echo "$tcp_retrans" | awk '{print $10}')
    local tcp_in_segs
    tcp_in_segs=$(echo "$tcp_retrans" | awk '{print $5}')
    
    # Connection tracking
    local tcp_established
    tcp_established=$(ss -s 2>/dev/null | grep TCP | awk '{print $4}' || echo "0")
    local tcp_time_wait
    tcp_time_wait=$(ss -s 2>/dev/null | grep TCP | awk '{print $6}' || echo "0")
    
    # Packet drops
    local rx_dropped
    rx_dropped=$(</proc/net/dev grep -v lo | awk '{sum+=$4} END {print sum}')
    local tx_dropped
    tx_dropped=$(</proc/net/dev grep -v lo | awk '{sum+=$14} END {print sum}')
    
    echo "$timestamp,$syncookies_sent,$syncookies_recv,$syncookies_failed,$embryonic_rsts,$prune_called,$tcp_retrans_segs,$tcp_out_segs,$tcp_in_segs,$tcp_established,$tcp_time_wait,$rx_dropped,$tx_dropped" >> "$output_file"
}

# Block I/O detailed metrics (Gregg's I/O analysis)
capture_block_io_metrics() {
    local output_file="$1"
    local timestamp
    timestamp=$(date +%s)
    
    # Get block device stats
    local read_ios=0 write_ios=0 read_bytes=0 write_bytes=0 read_time=0 write_time=0
    
    # shellcheck disable=SC2034
    while read -r device read_ios_temp read_merges read_sectors read_time_temp write_ios_temp write_merges write_sectors write_time_temp current ios_weight; do
        if [ "$device" != "Device:" ] && [ -n "$device" ]; then
            read_ios=$((read_ios + read_ios_temp))
            write_ios=$((write_ios + write_ios_temp))
            read_bytes=$((read_bytes + read_sectors * 512))  # sectors to bytes
            write_bytes=$((write_bytes + write_sectors * 512))
            read_time=$((read_time + read_time_temp))
            write_time=$((write_time + write_time_temp))
        fi
    done < <(grep -E '^[a-z]+' /proc/diskstats)
    
    # I/O queue depth
    local queue_depth=0
    if [ -f /proc/queue_depth ]; then
        queue_depth=$(</proc/queue_depth)
    fi
    
    # I/O scheduler statistics
    local nr_inflight
    nr_inflight=$(</proc/diskstats awk '{sum+=$12} END {print sum}')
    
    echo "$timestamp,$read_ios,$write_ios,$read_bytes,$write_bytes,$read_time,$write_time,$queue_depth,$nr_inflight" >> "$output_file"
}

# Start kernel metrics collection
start_kernel_metrics_collection() {
    local output_dir="$1"
    local target_pid="$2"
    
    mkdir -p "${output_dir}/kernel_metrics"
    
    local kernel_file="${output_dir}/kernel_metrics/kernel_metrics.csv"
    local process_file="${output_dir}/kernel_metrics/process_metrics.csv"
    local network_file="${output_dir}/kernel_metrics/network_stack.csv"
    local block_io_file="${output_dir}/kernel_metrics/block_io.csv"
    
    # Create CSV headers
    echo "timestamp,runqueue,runnable,blocked,ctxt,intr,softirq,nr_free_pages,nr_inactive_anon,nr_active_anon,nr_inactive_file,nr_active_file,pgmajfault,nr_dirty,nr_writeback,tcp_active,tcp_passive,tcp_retrans_segs" > "$kernel_file"
    echo "timestamp,pid,utime,stime,cutime,cstime,threads,vsize,rss,rss_anon,rss_file,read_bytes,write_bytes,read_ops,write_ops,fd_count,vol_ctxt,nonvol_ctxt" > "$process_file"
    echo "timestamp,syncookies_sent,syncookies_recv,syncookies_failed,embryonic_rsts,prune_called,tcp_retrans_segs,tcp_out_segs,tcp_in_segs,tcp_established,tcp_time_wait,rx_dropped,tx_dropped" > "$network_file"
    echo "timestamp,read_ios,write_ios,read_bytes,write_bytes,read_time,write_time,queue_depth,nr_inflight" > "$block_io_file"
    
    # Start collection loops
    {
        while true; do
            capture_kernel_metrics_data "$kernel_file"
            sleep 1
        done
    } &
    KERNEL_METRICS_PID=$!
    echo "$KERNEL_METRICS_PID" > "${output_dir}/kernel_metrics/kernel.pid"
    
    # Process metrics (if target PID provided)
    if [ -n "$target_pid" ]; then
        {
            while true; do
                capture_process_metrics "$process_file" "$target_pid"
                sleep 1
            done
        } &
        PROCESS_METRICS_PID=$!
        echo "$PROCESS_METRICS_PID" > "${output_dir}/kernel_metrics/process.pid"
    fi
    
    # Network stack metrics
    {
        while true; do
            capture_network_stack_metrics "$network_file"
            sleep 2
        done
    } &
    NETWORK_METRICS_PID=$!
    echo "$NETWORK_METRICS_PID" > "${output_dir}/kernel_metrics/network.pid"
    
    # Block I/O metrics
    {
        while true; do
            capture_block_io_metrics "$block_io_file"
            sleep 1
        done
    } &
    BLOCKIO_METRICS_PID=$!
    echo "$BLOCKIO_METRICS_PID" > "${output_dir}/kernel_metrics/blockio.pid"
    
    echo "Kernel-level metrics collection started in ${output_dir}/kernel_metrics/"
}

# Stop kernel metrics collection
stop_kernel_metrics_collection() {
    local output_dir="$1"
    
    for pid_file in "${output_dir}/kernel_metrics"/*.pid; do
        if [ -f "$pid_file" ]; then
            local pid
            pid=$(cat "$pid_file")
            kill -TERM "$pid" 2>/dev/null || true
            rm -f "$pid_file"
        fi
    done
    
    echo "Kernel metrics collection stopped"
}

# Generate kernel analysis report
generate_kernel_analysis_report() {
    local output_dir="$1"
    local scenario_name="$2"
    local report_file="${output_dir}/kernel_deep_dive_${scenario_name}.md"
    
    cat > "$report_file" << EOF
# Kernel-Level Performance Deep Dive

**Scenario:** $scenario_name  
**Generated:** $(date)  
**Methodology:** Brendan Gregg's Kernel Analysis Techniques

---

## Process Scheduling Analysis

### Run Queue Behavior
EOF

    # Analyze run queue patterns
    if [ -f "${output_dir}/kernel_metrics/kernel_metrics.csv" ]; then
        {
            echo '```bash'
            echo "# Run queue statistics"
            tail -10 "${output_dir}/kernel_metrics/kernel_metrics.csv" | cut -d',' -f2 | awk '{sum+=$1; if(NR==1) min=$1; if($1<min) min=$1; if($1>max) max=$1} END {print "Average: " sum/NR ", Min: " min ", Max: " max}'
            echo '```'
        } >> "$report_file"
    fi

    if [ -f "${output_dir}/kernel_metrics/process_metrics.csv" ]; then
        {
            echo '```bash'
            echo "# Process context switches (last 10 samples)"
            tail -10 "${output_dir}/kernel_metrics/process_metrics.csv" | cut -d',' -f17,18 | awk -F, '{vol+=$1; nonvol+=$2} END {print "Voluntary: " vol ", Non-voluntary: " nonvol}'
            echo '```'
        } >> "$report_file"
    fi

    cat >> "$report_file" << EOF

---

## Memory Subsystem Analysis

### Page Fault Patterns
Page faults indicate memory pressure and access patterns.

EOF

    if [ -f "${output_dir}/kernel_metrics/kernel_metrics.csv" ]; then
        {
            echo '```bash'
            echo "# Major page faults (last 10 samples)"
            tail -10 "${output_dir}/kernel_metrics/kernel_metrics.csv" | cut -d',' -f14 | awk '{sum+=$1} END {print "Total Major Page Faults: " sum}'
            echo '```'
        } >> "$report_file"
    fi

    {
        echo "### TCP Performance"
        echo '```bash'
        echo "# TCP Retransmission Rate"
        tail -10 "${output_dir}/kernel_metrics/network_stack.csv" | awk -F, '{retrans+=$7; out+=$8} END {if(out>0) print "Retransmission Rate: " (retrans/out*100) "%"; else print "No outbound traffic"}'
        echo '```'
    } >> "$report_file"

    {
        echo "### I/O Latency Patterns"
        echo '```bash'
        echo "# I/O Operations Summary"
        tail -10 "${output_dir}/kernel_metrics/block_io.csv" | awk -F, '{read+=$2; write+=$3; read_bytes+=$4; write_bytes+=$5; read_time+=$6; write_time+=$7} END {
            if(read>0) print "Read IOPS: " read ", Avg Read Latency: " (read_time/read) "ms";
            if(write>0) print "Write IOPS: " write ", Avg Write Latency: " (write_time/write) "ms";
            print "Total Read: " (read_bytes/1024/1024) "MB, Total Write: " (write_bytes/1024/1024) "MB"
        }'
        echo '```'
    } >> "$report_file"

    cat >> "$report_file" << 'EOF'

---

## Gregg's USE Method Analysis

### Utilization
- **CPU:** [Analyze from kernel metrics]
- **Memory:** [Analyze from vmstat data]
- **Network:** [Analyze from TCP stats]
- **Storage:** [Analyze from I/O metrics]

### Saturation
- **CPU Run Queue:** [Load average analysis]
- **Memory Pressure:** [Page fault patterns]
- **Network Congestion:** [TCP retransmissions]
- **I/O Queue Depth:** [Block I/O saturation]

### Errors
- **Network Errors:** [TCP resets, drops]
- **I/O Errors:** [Failed operations]
- **Memory Errors:** [OOM events if any]

---

## Recommendations

Based on kernel-level analysis following Gregg's methodology:

1. **Scheduler Optimization:** [Based on context switches and run queue]
2. **Memory Tuning:** [Based on page fault patterns]
3. **Network Stack Tuning:** [Based on TCP metrics]
4. **I/O Optimization:** [Based on block I/O analysis]

---

**Note:** This analysis requires root privileges for complete kernel visibility. Some metrics may be limited in non-privileged environments.

EOF

    echo "Kernel analysis report generated: $report_file"
}