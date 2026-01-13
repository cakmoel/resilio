#!/bin/bash
# shellcheck shell=bash
# =============================================================================
# Brendan Gregg's System Profiling Tools Integration for Resilio DLT
# =============================================================================

# BASE_DIR is expected to be defined by the sourcing script (bin/dlt.sh)

# Check for required tools
check_gregg_tools() {
    local missing_tools=()
    
    if ! command -v perf &>/dev/null; then missing_tools+=("perf"); fi
    if ! command -v bpftrace &>/dev/null; then missing_tools+=("bpftrace"); fi
    if ! command -v tcpdump &>/dev/null; then missing_tools+=("tcpdump"); fi
    if ! command -v ss &>/dev/null; then missing_tools+=("ss"); fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "WARNING: Missing Brendan Gregg tools: ${missing_tools[*]}"
        echo "Install: sudo apt-get install linux-tools-generic linux-cloud-tools-generic bpftrace tcpdump"
        return 1
    fi
    return 0
}

# CPU Performance Analysis (Gregg's perf integration)
start_cpu_profiling() {
    local output_dir="$1"
    local pid="$2"  # Target application PID
    
    mkdir -p "${output_dir}/cpu_profiling"
    
    # Start perf record for CPU cycles
    if command -v perf &>/dev/null && [ -n "$pid" ]; then
        perf record -F 99 -p "$pid" -g --call-graph dwarf -o "${output_dir}/cpu_profiling/perf.data" &
        PERF_PID=$!
        echo "$PERF_PID" > "${output_dir}/cpu_profiling/perf.pid"
        
        # Start perf stat for overall CPU stats
        perf stat -e cycles,instructions,cache-references,cache-misses,branches,branch-misses -p "$pid" -o "${output_dir}/cpu_profiling/perf_stat.log" &
        PERF_STAT_PID=$!
        echo "$PERF_STAT_PID" > "${output_dir}/cpu_profiling/perf_stat.pid"
    fi
}

# Memory Analysis (Gregg's memory tools)
start_memory_profiling() {
    local output_dir="$1"
    local pid="$2"
    
    mkdir -p "${output_dir}/memory_profiling"
    
    # Page fault tracking
    if command -v bpftrace &>/dev/null; then
        cat > "${output_dir}/memory_profiling/pagefaults.bt" << 'EOF'
#!/usr/bin/env bpftrace
BEGIN {
    printf("Tracing page faults... Hit Ctrl-C to end.\n");
    printf("%-8s %-16s %-6s %-16s %s\n", "TIME", "COMM", "PID", "FUNC", "LATENCY");
}

tracepoint:exceptions:page_fault_user {
    $latency = (args->flags & FAULT_FLAG_ALLOW_RETRY) ? "major" : "minor";
    printf("%-8s %-16s %-6d %-16s %s\n", 
        strftime("%H:%M:%S"), comm, pid, probe, $latency);
}
EOF
        
        bpftrace "${output_dir}/memory_profiling/pagefaults.bt" > "${output_dir}/memory_profiling/pagefaults.log" 2>&1 &
        BPFTRACE_PID=$!
        echo "$BPFTRACE_PID" > "${output_dir}/memory_profiling/bpftrace.pid"
    fi
}

# Network Stack Analysis (Gregg's network tools)
start_network_profiling() {
    local output_dir="$1"
    local interface="${2:-eth0}"
    
    mkdir -p "${output_dir}/network_profiling"
    
    # TCP connection tracking
    if command -v ss &>/dev/null; then
        while true; do
            echo "$(date +%s)" >> "${output_dir}/network_profiling/ss_stats.log"
            ss -s >> "${output_dir}/network_profiling/ss_stats.log"
            sleep 2
        done &
        SS_PID=$!
        echo "$SS_PID" > "${output_dir}/network_profiling/ss.pid"
    fi
    
    # Network latency tracking with bpftrace
    if command -v bpftrace &>/dev/null; then
        cat > "${output_dir}/network_profiling/tcp_latency.bt" << 'EOF'
#!/usr/bin/env bpftrace
tracepoint:tcp:tcp_set_state {
    if (args->oldstate == TCP_LISTEN && args->newstate == TCP_ESTABLISHED) {
        printf("Connection established: %s -> %s (%d)\n", 
            args->saddr, args->daddr, pid);
    }
    
    if (args->oldstate == TCP_ESTABLISHED && args->newstate == TCP_CLOSE_WAIT) {
        printf("Connection closing: %s -> %s (%d)\n", 
            args->saddr, args->daddr, pid);
    }
}
EOF
        
        bpftrace "${output_dir}/network_profiling/tcp_latency.bt" > "${output_dir}/network_profiling/tcp_latency.log" 2>&1 &
        NETWORK_BPF_PID=$!
        echo "$NETWORK_BPF_PID" > "${output_dir}/network_profiling/network_bpf.pid"
    fi
}

# I/O Analysis (Gregg's block I/O tools)
start_io_profiling() {
    local output_dir="$1"
    
    mkdir -p "${output_dir}/io_profiling"
    
    # Block I/O latency tracking
    if command -v bpftrace &>/dev/null; then
        cat > "${output_dir}/io_profiling/block_io.bt" << 'EOF'
#!/usr/bin/env bpftrace
tracepoint:block:block_rq_issue {
    @start[args->dev] = nsecs;
}

tracepoint:block:block_rq_complete {
    $start = @start[args->dev];
    if ($start) {
        $latency = nsecs - $start;
        @latency[args->dev] = hist($latency / 1000); // Convert to microseconds
        delete(@start[args->dev]);
    }
}

END {
    clear(@start);
    print(@latency);
}
EOF
        
        bpftrace "${output_dir}/io_profiling/block_io.bt" > "${output_dir}/io_profiling/block_io.log" 2>&1 &
        IO_BPF_PID=$!
        echo "$IO_BPF_PID" > "${output_dir}/io_profiling/io_bpf.pid"
    fi
    
    # Enhanced iostat with -xz flags (Gregg's recommendation)
    if command -v iostat &>/dev/null; then
        while true; do
            echo "$(date +%s)" >> "${output_dir}/io_profiling/iostat_xz.log"
            iostat -xz 1 1 >> "${output_dir}/io_profiling/iostat_xz.log"
            sleep 1
        done &
        IOSTAT_PID=$!
        echo "$IOSTAT_PID" > "${output_dir}/io_profiling/iostat.pid"
    fi
}

# Enhanced System Metrics (Gregg's comprehensive approach)
capture_gregg_system_metrics() {
    local output_file="$1"
    local timestamp=$(date +%s)
    
    # CPU metrics with load average
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[[:space:]]*//')
    
    # Memory stats
    local mem_stats=$(free -m | awk 'NR==2{print $3","$4","$6","$7}')
    
    # Context switches (Gregg's key metric)
    local ctxt=$(grep ctxt /proc/stat | awk '{print $2}')
    
    # Process stats
    local procs_running=$(grep procs_running /proc/stat | awk '{print $2}')
    local procs_blocked=$(grep procs_blocked /proc/stat | awk '{print $2}')
    
    # Network stats
    local tcp_stats=$(cat /proc/net/snmp | grep Tcp: | tail -1 | awk '{print $9","$10","$11","$12}')  # Active, passive, failed, resets
    
    echo "$timestamp,${cpu_usage:-0},$load_avg,$mem_stats,$ctxt,$procs_running,$procs_blocked,$tcp_stats" >> "$output_file"
}

# Stop all profiling sessions
stop_system_profiling() {
    local output_dir="$1"
    
    # Stop perf sessions
    if [ -f "${output_dir}/cpu_profiling/perf.pid" ]; then
        local perf_pid=$(cat "${output_dir}/cpu_profiling/perf.pid")
        kill -INT "$perf_pid" 2>/dev/null || true
        
        # Generate perf report
        if [ -f "${output_dir}/cpu_profiling/perf.data" ]; then
            perf report -i "${output_dir}/cpu_profiling/perf.data" > "${output_dir}/cpu_profiling/perf_report.txt" 2>&1
        fi
        
        if [ -f "${output_dir}/cpu_profiling/perf_stat.pid" ]; then
            local perf_stat_pid=$(cat "${output_dir}/cpu_profiling/perf_stat.pid")
            kill -TERM "$perf_stat_pid" 2>/dev/null || true
        fi
    fi
    
    # Stop bpftrace sessions
    for pid_file in "${output_dir}"/**/*.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    
    # Stop monitoring loops
    for pid_file in "${output_dir}"/**/*stat.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
}

# Generate Flame Graph (Gregg's signature visualization)
generate_flame_graph() {
    local output_dir="$1"
    local scenario_name="$2"
    
    if [ ! -f "${output_dir}/cpu_profiling/perf.data" ]; then
        echo "No perf data found for flame graph generation"
        return 1
    fi
    
    mkdir -p "${output_dir}/flamegraphs"
    
    # Check if FlameGraph tools are available
    if command -v stackcollapse-perf.pl &>/dev/null && command -v flamegraph.pl &>/dev/null; then
        perf script -i "${output_dir}/cpu_profiling/perf.data" | \
        stackcollapse-perf.pl | \
        flamegraph.pl > "${output_dir}/flamegraphs/${scenario_name}_flamegraph.svg"
        
        echo "Flame graph generated: ${output_dir}/flamegraphs/${scenario_name}_flamegraph.svg"
    else
        echo "FlameGraph tools not found. Install from: https://github.com/brendangregg/FlameGraph"
        return 1
    fi
}

# Start comprehensive profiling (main entry point)
start_comprehensive_profiling() {
    local output_dir="$1"
    local target_pid="$2"
    local interface="${3:-eth0}"
    
    # Check tools availability
    check_gregg_tools
    
    echo "Starting Brendan Gregg's comprehensive system profiling..."
    
    # Start all profiling modules
    start_cpu_profiling "$output_dir" "$target_pid"
    start_memory_profiling "$output_dir" "$target_pid"
    start_network_profiling "$output_dir" "$interface"
    start_io_profiling "$output_dir"
    
    # Enhanced system metrics collection
    mkdir -p "${output_dir}/gregg_metrics"
    
    # Start enhanced metrics collection loop
    while true; do
        capture_gregg_system_metrics "${output_dir}/gregg_metrics/enhanced_system_metrics.csv"
        sleep 1
    done &
    GREGG_METRICS_PID=$!
    echo "$GREGG_METRICS_PID" > "${output_dir}/gregg_metrics/metrics.pid"
    
    echo "Comprehensive profiling started. Monitoring PIDs saved to respective directories."
}

# Generate comprehensive analysis report
generate_gregg_analysis_report() {
    local output_dir="$1"
    local scenario_name="$2"
    local report_file="${output_dir}/gregg_comprehensive_analysis_${scenario_name}.md"
    
    cat > "$report_file" << EOF
# Brendan Gregg's System Performance Analysis

**Scenario:** $scenario_name  
**Generated:** $(date)  
**Analysis Type:** Deep System Performance (Gregg Methodology)

---

## Executive Summary

This report provides Brendan Gregg's comprehensive system performance analysis, going beyond HTTP metrics to identify root causes of performance bottlenecks.

---

## CPU Performance Analysis

EOF

    # Add CPU analysis if available
    if [ -f "${output_dir}/cpu_profiling/perf_report.txt" ]; then
        echo "### CPU Hotspots" >> "$report_file"
        echo '```' >> "$report_file"
        head -50 "${output_dir}/cpu_profiling/perf_report.txt" >> "$report_file"
        echo '```' >> "$report_file"
    fi

    # Add flame graph if available
    if [ -f "${output_dir}/flamegraphs/${scenario_name}_flamegraph.svg" ]; then
        echo "### CPU Flame Graph" >> "$report_file"
        echo "![Flame Graph](flamegraphs/${scenario_name}_flamegraph.svg)" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

---

## Memory Analysis

EOF

    # Add memory analysis
    if [ -f "${output_dir}/memory_profiling/pagefaults.log" ]; then
        echo "### Page Fault Analysis" >> "$report_file"
        echo '```' >> "$report_file"
        head -30 "${output_dir}/memory_profiling/pagefaults.log" >> "$report_file"
        echo '```' >> "$report_file"
    fi

    cat >> "$report_file" << EOF

---

## Network Stack Analysis

EOF

    # Add network analysis
    if [ -f "${output_dir}/network_profiling/ss_stats.log" ]; then
        echo "### TCP Connection Statistics" >> "$report_file"
        echo '```' >> "$report_file"
        tail -20 "${output_dir}/network_profiling/ss_stats.log" >> "$report_file"
        echo '```' >> "$report_file"
    fi

    cat >> "$report_file" << EOF

---

## I/O Performance Analysis

EOF

    # Add I/O analysis
    if [ -f "${output_dir}/io_profiling/block_io.log" ]; then
        echo "### Block I/O Latency Distribution" >> "$report_file"
        echo '```' >> "$report_file"
        cat "${output_dir}/io_profiling/block_io.log" >> "$report_file"
        echo '```' >> "$report_file"
    fi

    if [ -f "${output_dir}/io_profiling/iostat_xz.log" ]; then
        echo "### Enhanced I/O Statistics (-xz flags)" >> "$report_file"
        echo '```' >> "$report_file"
        tail -30 "${output_dir}/io_profiling/iostat_xz.log" >> "$report_file"
        echo '```' >> "$report_file"
    fi

    cat >> "$report_file" << EOF

---

## System-Level Correlations

This analysis correlates HTTP performance metrics with system-level indicators following Gregg's USE Method:

- **Utilization**: CPU, Memory, Network, Disk utilization patterns
- **Saturation**: Queue lengths, load averages, connection backlogs  
- **Errors**: Retransmits, failed requests, page faults

### Key Findings

1. **CPU Utilization**: [Analyze from perf data]
2. **Memory Pressure**: [Analyze from page faults]
3. **Network Saturation**: [Analyze from TCP stats]
4. **I/O Bottlenecks**: [Analyze from block I/O latency]

---

## Recommendations

Based on Brendan Gregg's methodology:

EOF

    # Add recommendations based on analysis results
    echo "1. **CPU Optimization**: $(grep -i cpu "${output_dir}/cpu_profiling/perf_report.txt" | head -1 || echo "Consider CPU profiling for optimization")" >> "$report_file"
    echo "2. **Memory Tuning**: $(grep -i memory "${output_dir}/memory_profiling/pagefaults.log" | head -1 || echo "Monitor page fault patterns")" >> "$report_file"  
    echo "3. **Network Optimization**: $(grep -i tcp "${output_dir}/network_profiling/tcp_latency.log" | head -1 || echo "Analyze TCP connection patterns")" >> "$report_file"

    echo "Report generated: $report_file"
}