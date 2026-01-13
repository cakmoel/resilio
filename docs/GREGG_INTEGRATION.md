# Installing Brendan Gregg's Tools Integration

This guide helps you install the enhanced DLT with Brendan Gregg's system performance analysis tools.

## Prerequisites

### Basic Requirements (already in project)
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install apache2-utils bc gawk grep coreutils sysstat python3 python3-pip

# CentOS/RHEL/Fedora  
sudo yum install httpd-tools bc gawk grep coreutils sysstat python3 python3-pip

# macOS
brew install apache2 coreutils
```

### Brendan Gregg's Enhanced Tools

#### Install Linux Performance Tools
```bash
# Ubuntu/Debian
sudo apt-get install \
    linux-tools-generic \
    linux-cloud-tools-generic \
    bpftrace \
    tcpdump \
    perf-tools-unstable \
    sysstat

# Alternative for latest perf tools
sudo apt-get install linux-tools-$(uname -r) linux-cloud-tools-$(uname -r)

# Install bpftrace dependencies
sudo apt-get install llvm-12 clang-12 libc++-12-dev libc++abi-12-dev
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++12 100
```

#### Install FlameGraph Tools
```bash
cd /tmp
git clone https://github.com/brendangregg/FlameGraph.git
sudo cp FlameGraph/*.pl /usr/local/bin/
sudo chmod +x /usr/local/bin/*.pl
```

#### Install Additional Analysis Tools
```bash
# Network analysis tools
sudo apt-get install nmap iproute2

# I/O analysis tools  
sudo apt-get install iotop

# System analysis tools
sudo apt-get install htop iotop strace ltrace

# Container support (if using Docker/Kubernetes)
sudo apt-get install docker.io kubectl
```

## Configuration

### 1. Update Configuration
Edit `config/dlt_gregg.conf` based on your environment:

```bash
# Enable Gregg's profiling
ENABLE_GREGG_PROFILING=true
ENABLE_KERNEL_METRICS=true
ENABLE_FLAME_GRAPHS=true

# Target application (auto-detect if empty)
TARGET_APP_PID=""
TARGET_INTERFACE="eth0"

# Profiling intervals
SYSTEM_METRICS_INTERVAL=1
KERNEL_METRICS_INTERVAL=1
```

### 2. Environment Setup
```bash
# Set up environment for your application
echo "APP_ENV=local" > .env

# Optional: Specify target application
echo "TARGET_APP_PID=$(pgrep apache2 | head -1)" >> .env
```

### 3. Permissions Setup
For full system profiling capabilities:

```bash
# Option 1: Run with sudo (recommended for full visibility)
sudo ./bin/dlt_gregg.sh

# Option 2: Set up permissions without sudo (limited capabilities)
# Add user to perf group (if exists)
sudo usermod -a -G perf $USER

# Or set perf_paranoid level
echo 0 | sudo tee /proc/sys/kernel/perf_paranoid
```

## Usage Examples

### Basic Enhanced Load Testing
```bash
# Run with all Gregg's features enabled
./bin/dlt_gregg.sh

# Specific configuration
ENABLE_GREGG_PROFILING=true ENABLE_FLAME_GRAPHS=true ./bin/dlt_gregg.sh
```

### Targeting Specific Applications
```bash
# Target a specific web server
TARGET_APP_PID=$(pgrep nginx) ./bin/dlt_gregg.sh

# Target Node.js application
TARGET_APP_PID=$(pgrep node) ./bin/dlt_gregg.sh

# Target PHP-FPM
TARGET_APP_PID=$(pgrep php-fpm) ./bin/dlt_gregg.sh
```

### Production Environment
```bash
# Production with Git-tracked baselines
echo "APP_ENV=production" > .env
echo "STATIC_PAGE=https://prod.example.com/" >> .env
echo "DYNAMIC_PAGE=https://prod.example.com/api/users" >> .env

ENABLE_GREGG_PROFILING=true ENABLE_KERNEL_METRICS=true sudo ./bin/dlt_gregg.sh
```

### Cloud/Container Environments
```bash
# Docker container metrics
ENABLE_CONTAINER_METRICS=true CONTAINER_RUNTIME=docker ./bin/dlt_gregg.sh

# Kubernetes pod analysis
ENABLE_CONTAINER_METRICS=true CONTAINER_RUNTIME=kubernetes ./bin/dlt_gregg.sh
```

## Understanding the Output

### Enhanced Report Structure
```
load_test_reports_YYYYMMDD_HHMMSS/
├── research_report_*.md              # Original DLT analysis
├── hypothesis_testing_*.md          # Statistical comparison
├── gregg_analysis/                   # Brendan Gregg's tools output
│   ├── cpu_profiling/
│   │   ├── perf.data                # CPU profiling data
│   │   ├── perf_report.txt          # CPU analysis
│   │   └── perf_stat.log            # CPU statistics
│   ├── memory_profiling/
│   │   ├── pagefaults.log           # Page fault analysis
│   │   └── pagefaults.bt            # bpftrace script
│   ├── network_profiling/
│   │   ├── ss_stats.log             # TCP connection stats
│   │   └── tcp_latency.log          # Network latency
│   ├── io_profiling/
│   │   ├── block_io.log             # Block I/O latency
│   │   └── iostat_xz.log            # Enhanced I/O stats
│   └── flamegraphs/                  # CPU flame graphs
│       └── *_flamegraph.svg         # Interactive flame graphs
├── kernel_metrics/                    # Kernel-level analysis
│   ├── kernel_metrics.csv            # System-wide metrics
│   ├── process_metrics.csv           # Process-specific metrics
│   ├── network_stack.csv             # Network stack metrics
│   └── block_io.csv                  # Block I/O metrics
├── system_metrics.csv                # Original system metrics
└── raw_data/                        # ApacheBench outputs
```

### Key Gregg Analysis Reports

#### CPU Performance Analysis
- **perf_report.txt**: CPU hotspots and function profiling
- **Flame graphs**: Interactive visualization of CPU usage
- **perf_stat.log**: CPU cycles, instructions, cache statistics

#### Memory Analysis  
- **pagefaults.log**: Major/minor page fault tracking
- **Memory pressure patterns**: Swap usage and memory allocation

#### Network Stack Analysis
- **TCP connection tracking**: Connection establishment/closure patterns
- **Network latency**: Packet-level latency analysis
- **TCP retransmissions**: Network congestion indicators

#### I/O Performance Analysis
- **Block I/O latency**: Disk operation timing
- **I/O queue depth**: Storage saturation analysis
- **Enhanced iostat**: Detailed I/O statistics with -xz flags

## Troubleshooting

### Permission Issues
```bash
# Error: Operation not permitted
# Solution: Run with sudo or adjust perf_paranoid
echo 0 | sudo tee /proc/sys/kernel/perf_paranoid
```

### Missing Tools
```bash
# Error: bpftrace not found
# Solution: Install bpftrace
sudo apt-get install bpftrace
```

### Flame Graph Generation
```bash
# Error: FlameGraph tools not found
# Solution: Install FlameGraph
git clone https://github.com/brendangregg/FlameGraph.git
sudo cp FlameGraph/*.pl /usr/local/bin/
```

## Advanced Configuration

### Custom bpftrace Scripts
You can create custom bpftrace scripts in the `gregg_analysis/` directory:

```bash
# Custom latency tracking
cat > custom_latency.bt << 'EOF'
#!/usr/bin/env bpftrace
tracepoint:sched:sched_switch {
    $latency = (args->prev_state == TASK_RUNNING) ? 0 : 
               (nsecs - args->prev_start_time);
    @latency_hist = hist($latency / 1000);
}
EOF
```

### Container-Specific Analysis
```bash
# Docker container profiling
docker stats --no-stream
docker exec <container> cat /proc/net/netstat

# Kubernetes pod analysis
kubectl top pods
kubectl exec <pod> -- cat /proc/loadavg
```

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Install Gregg's Tools
  run: |
    sudo apt-get update
    sudo apt-get install -y linux-tools-generic bpftrace perf-tools-unstable
    
- name: Enhanced Load Test
  run: |
    sudo ./bin/dlt_gregg.sh
    
- name: Upload Enhanced Reports
  uses: actions/upload-artifact@v3
  with:
    name: enhanced-performance-reports
    path: |
      load_test_reports_*/**
      gregg_analysis/**
      flamegraphs/**
```

## Performance Considerations

- **CPU Overhead**: Gregg's profiling adds ~2-5% CPU overhead
- **Memory Usage**: Additional ~50-100MB for profiling data
- **Disk Space**: Flame graphs can be 10-50MB each
- **Recommendation**: Use sampling (99Hz) for production testing

## Security Notes

- Profiling tools require elevated privileges
- Some bpftrace scripts may expose sensitive system data
- Consider using sandboxed environments for security testing
- Review profiling data before sharing externally