# Load Testing Scripts User Guide

## Introduction

This guide provides instructions for using two custom load testing scripts: `slt.sh` (Simple Load Testing) and `dlt.sh` (Deep Load Testing). These scripts are designed to help you measure and analyze the performance of web applications and APIs built with any technology stack including PHP, JavaScript (Node.js), Go, Python, Ruby, Java, or any other web technology.

Both scripts work by sending HTTP requests to your application endpoints and measuring the responses. They are technology-agnostic because they test your application through its HTTP interface, not its internal code.

## When to Use Each Script

### Use slt.sh (Simple Load Testing) when:

- You need quick performance metrics for your application
- You want to test specific endpoints with straightforward load patterns
- You need basic statistics like average requests per second, response times, and percentiles
- You are doing initial performance checks or quick benchmarks
- You have limited time and need immediate results
- You want to compare performance between different endpoints

### Use dlt.sh (Deep Load Testing) when:

- You need comprehensive performance analysis with statistical rigor
- You require detailed reports with confidence intervals and standard deviations
- You want to test how your application handles gradual load increases
- You need to identify performance bottlenecks and system behavior under sustained load
- You are conducting formal performance testing or capacity planning
- You need scientifically-backed metrics for stakeholder reports
- You want to detect memory leaks or performance degradation over time

## Prerequisites

Before using these scripts, ensure your system has the following installed:

### Required Software

1. Bash Shell - Available by default on Linux and macOS
2. ApacheBench (ab) - The core load testing tool
3. bc - Basic calculator for mathematical operations
4. awk - Text processing utility
5. grep - Pattern matching utility

### Installing Prerequisites

On Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install apache2-utils bc gawk grep coreutils
```

On CentOS/RHEL/Fedora:

```bash
sudo yum install httpd-tools bc gawk grep coreutils
```

On macOS:

```bash
brew install apache2
```

Note: bc, awk, and grep are typically pre-installed on macOS.

Verify Installation:

```bash
ab -V
bc --version
awk --version
grep --version
```

## Installation

### Step 1: Download the Scripts

Download both `slt.sh` and `dlt.sh` to your preferred directory.

### Step 2: Make Scripts Executable

```bash
chmod +x slt.sh
chmod +x dlt.sh
```

### Step 3: Verify Scripts are Ready

```bash
./slt.sh
./dlt.sh
```

If you see the scripts starting to run (they will begin testing), they are ready. Press Ctrl+C to stop.

## Configuring the Scripts

Before running the tests, you need to configure the URLs you want to test.

### Configuring slt.sh

Open `slt.sh` in a text editor and locate the SCENARIOS section (around line 40):

```bash
declare -A SCENARIOS=(
    ["Static"]="http://marsinah.hero/login"
    ["Dynamic"]="http://munir.killed/post/why-was-Munir-killed-by-the-state"
    ["404_Not_Found"]="http://esemka.local/this-page-is-not-real"
)
```

Replace these URLs with your application's endpoints:

```bash
declare -A SCENARIOS=(
    ["Homepage"]="http://your-app.com/"
    ["API_Endpoint"]="http://your-app.com/api/v1/users"
    ["Product_Page"]="http://your-app.com/products/123"
)
```

### Configuring dlt.sh

Open `dlt.sh` in a text editor and locate the SCENARIOS section (around line 64):

```bash
declare -A SCENARIOS=(
    ["Static"]="http://marsinah.hero/login"
    ["Dynamic"]="http://munir.killed/post/why-was-Munir-killed-by-the-state"
    ["API_Endpoint"]="http://zionist.evil/api/v1/posts"
    ["404_Error"]="http://republic.mafia/this-page-is-not-real"
)
```

Replace with your URLs:

```bash
declare -A SCENARIOS=(
    ["Homepage"]="http://your-app.com/"
    ["User_Dashboard"]="http://your-app.com/dashboard"
    ["API_Products"]="http://your-app.com/api/v1/products"
)
```

## Running the Scripts

### Running slt.sh (Simple Load Testing)

Basic Usage:

```bash
./slt.sh
```

This will run 1000 iterations with default settings.

With Custom Parameters:

```bash
ITERATIONS=500 AB_REQUESTS=50 AB_CONCURRENCY=5 ./slt.sh
```

Available Environment Variables:

- ITERATIONS - Number of test iterations (default: 1000)
- AB_REQUESTS - Requests per test (default: 100)
- AB_CONCURRENCY - Concurrent users (default: 10)
- AB_TIMEOUT - Timeout in seconds (default: 30)

Example for Light Testing:

```bash
ITERATIONS=100 AB_REQUESTS=50 AB_CONCURRENCY=5 ./slt.sh
```

Example for Heavy Testing:

```bash
ITERATIONS=2000 AB_REQUESTS=500 AB_CONCURRENCY=50 ./slt.sh
```

### Running dlt.sh (Deep Load Testing)

Basic Usage:

```bash
./dlt.sh
```

This executes a comprehensive three-phase test: warm-up, ramp-up, and sustained load.

Understanding dlt.sh Parameters:

The script uses research-based parameters that are pre-configured:

- Total iterations: 1000 (50 warm-up + 100 ramp-up + 850 sustained)
- Requests per test: 1000
- Concurrency: 50 users
- Think time: 2000ms between requests

These values are optimized for statistical validity and should not be changed unless you understand the research methodology.

## Understanding the Results

### slt.sh Output

After the test completes, you will find results in a timestamped directory:

```
load_test_results_YYYYMMDD_HHMMSS/
  - summary_report.md          (Main report)
  - console_output.log         (Test execution log)
  - execution.log              (Detailed execution log)
  - error.log                  (Error tracking)
  - raw_*.txt                  (Raw ApacheBench outputs)
```

Key Metrics in the Report:

- Average RPS (Requests Per Second) - Throughput of your application
- Median RPS - Middle value, less affected by outliers
- Standard Deviation - Consistency of performance
- P50/P95/P99 - Percentile response times
- Success Rate - Percentage of successful requests
- Error Rate - Percentage of failed requests

### dlt.sh Output

Results are saved in a research-grade report directory:

```
load_test_reports_YYYYMMDD_HHMMSS/
  - research_report_YYYYMMDD_HHMMSS.md  (Comprehensive report)
  - system_metrics.csv                   (CPU, memory, disk metrics)
  - error_log.txt                        (Error tracking)
  - execution.log                        (Test phases log)
  - raw_data/                            (All raw test outputs)
  - charts/                              (Reserved for chart generation)
```

Key Metrics in the Report:

- Mean with 95% Confidence Intervals - Statistical accuracy
- Median and Standard Deviation - Distribution analysis
- P95/P99 Latency - Tail latency for SLA validation
- Connection Time vs Processing Time - Bottleneck identification
- Coefficient of Variation - Stability indicator
- Error Rate and Success Rate - Reliability metrics

## Testing Different Technologies

These scripts work with ANY web technology because they test through HTTP endpoints. The scripts use ApacheBench which sends HTTP requests and measures responses - it does not care what technology processes those requests on the server side.

### Why It Works with Any Technology

The scripts are technology-agnostic because:

1. They communicate via HTTP protocol (the universal web standard)
2. They only measure request/response cycles
3. They do not interact with your application code directly
4. They work like a web browser sending requests to your server

Whether your server processes requests with PHP, Node.js, Python, Go, Ruby, Java, or any other language, the HTTP interface remains the same.

### Testing PHP Applications

Laravel Example:

```bash
declare -A SCENARIOS=(
    ["Home"]="http://localhost:8000/"
    ["API_Users"]="http://localhost:8000/api/users"
    ["Login_Page"]="http://localhost:8000/login"
)
```

WordPress Example:

```bash
declare -A SCENARIOS=(
    ["Homepage"]="http://localhost/wordpress/"
    ["Post_Page"]="http://localhost/wordpress/2024/01/sample-post/"
    ["API"]="http://localhost/wordpress/wp-json/wp/v2/posts"
)
```

### Testing JavaScript (Node.js) Applications

Express.js Example:

```bash
declare -A SCENARIOS=(
    ["API_Status"]="http://localhost:3000/api/status"
    ["Users_List"]="http://localhost:3000/api/users"
    ["Products"]="http://localhost:3000/api/products"
)
```

Next.js Example:

```bash
declare -A SCENARIOS=(
    ["Homepage"]="http://localhost:3000/"
    ["API_Route"]="http://localhost:3000/api/data"
    ["Dynamic_Page"]="http://localhost:3000/blog/post-1"
)
```

### Testing Python Applications

Django Example:

```bash
declare -A SCENARIOS=(
    ["Homepage"]="http://localhost:8000/"
    ["API_Items"]="http://localhost:8000/api/items/"
    ["Admin"]="http://localhost:8000/admin/"
)
```

Flask Example:

```bash
declare -A SCENARIOS=(
    ["Index"]="http://localhost:5000/"
    ["API_Data"]="http://localhost:5000/api/data"
)
```

FastAPI Example:

```bash
declare -A SCENARIOS=(
    ["Docs"]="http://localhost:8000/docs"
    ["API_Users"]="http://localhost:8000/api/v1/users"
    ["Health"]="http://localhost:8000/health"
)
```

### Testing Go Applications

Standard Go HTTP Server:

```bash
declare -A SCENARIOS=(
    ["Health"]="http://localhost:8080/health"
    ["API_V1"]="http://localhost:8080/api/v1/resources"
)
```

Gin Framework:

```bash
declare -A SCENARIOS=(
    ["Ping"]="http://localhost:8080/ping"
    ["API_Products"]="http://localhost:8080/api/products"
)
```

### Testing Ruby Applications

Rails Example:

```bash
declare -A SCENARIOS=(
    ["Root"]="http://localhost:3000/"
    ["API_Posts"]="http://localhost:3000/api/v1/posts"
    ["Users"]="http://localhost:3000/users"
)
```

Sinatra Example:

```bash
declare -A SCENARIOS=(
    ["Home"]="http://localhost:4567/"
    ["API"]="http://localhost:4567/api/data"
)
```

### Testing Java Applications

Spring Boot Example:

```bash
declare -A SCENARIOS=(
    ["Actuator"]="http://localhost:8080/actuator/health"
    ["API_Products"]="http://localhost:8080/api/products"
    ["Dashboard"]="http://localhost:8080/dashboard"
)
```

### Testing .NET Applications

ASP.NET Core Example:

```bash
declare -A SCENARIOS=(
    ["Home"]="http://localhost:5000/"
    ["API_WeatherForecast"]="http://localhost:5000/api/weatherforecast"
    ["Health"]="http://localhost:5000/health"
)
```

### Testing Rust Applications

Actix-web Example:

```bash
declare -A SCENARIOS=(
    ["Index"]="http://localhost:8080/"
    ["API_Users"]="http://localhost:8080/api/users"
)
```

## Best Practices

### Before Running Tests

1. Test in a Non-Production Environment - Never run load tests against production servers without proper authorization
2. Warm Up Your Application - Start your application and let it initialize completely before testing
3. Check Resource Limits - Ensure your testing machine has sufficient resources
4. Disable Rate Limiting - Temporarily disable rate limiting or IP blocking during tests
5. Monitor Your Application - Keep application logs and monitoring tools open during tests

### During Tests

1. Start Small - Begin with low concurrency and few iterations
2. Gradually Increase Load - Use dlt.sh for automatic gradual load increase
3. Monitor System Resources - Watch CPU, memory, and disk usage
4. Document Conditions - Note any special conditions or configurations

### Interpreting Results

1. Compare Against Baselines - Establish baseline performance metrics
2. Look for Patterns - Identify performance degradation patterns
3. Focus on Percentiles - P95 and P99 are more important than averages
4. Check Error Rates - Any error rate above 1% requires investigation
5. Analyze Standard Deviation - High standard deviation indicates unstable performance

## Common Issues and Solutions

Issue: Connection Refused

Solution: Verify your application is running and accessible at the specified URL

```bash
curl http://localhost:8000/
```

Issue: Timeout Errors

Solution: Increase AB_TIMEOUT or reduce AB_CONCURRENCY

```bash
AB_TIMEOUT=60 AB_CONCURRENCY=5 ./slt.sh
```

Issue: Too Many Open Files

Solution: Increase system file descriptor limits

```bash
ulimit -n 10000
```

Issue: Script Permission Denied

Solution: Ensure scripts are executable

```bash
chmod +x slt.sh dlt.sh
```

Issue: Command Not Found (ab, bc, etc.)

Solution: Install missing prerequisites as described in the Prerequisites section

## Advanced Usage

### Testing Authenticated Endpoints

To test endpoints that require authentication, you need to modify the ab command in the scripts to include authentication headers.

Open the script and locate the ab command (around line 200 in slt.sh or line 350 in dlt.sh):

```bash
timeout $TEST_TIMEOUT ab -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

Replace with:

```bash
timeout $TEST_TIMEOUT ab -H "Authorization: Bearer YOUR_TOKEN" -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

### Testing POST Requests

For POST requests with data, modify the ab command:

```bash
timeout $TEST_TIMEOUT ab -p postdata.txt -T "application/json" -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

Create a `postdata.txt` file with your JSON payload:

```json
{"username":"test","password":"test123"}
```

### Running Tests in Background

To run tests in the background and continue working:

```bash
nohup ./slt.sh > test_output.log 2>&1 &
```

Check progress:

```bash
tail -f test_output.log
```

## Comparing Results Across Technologies

When comparing performance across different technologies, ensure:

1. Same Hardware - Run tests on identical server specifications
2. Same Network Conditions - Use consistent network setup
3. Same Database - If applicable, use the same database with identical data
4. Same Test Scenarios - Use equivalent endpoints (e.g., list 100 users)
5. Same Load Parameters - Use identical ITERATIONS, AB_REQUESTS, and AB_CONCURRENCY values

## Technical Explanation: Why These Scripts Work Universally

These scripts leverage ApacheBench, which operates at the HTTP protocol level. Here's why it works with any technology:

### The HTTP Protocol Layer

When a web browser or tool like ApacheBench makes a request:

1. Client sends HTTP request to server
2. Server receives request (regardless of backend language)
3. Application processes request using its technology (PHP, Node.js, etc.)
4. Server sends HTTP response back to client
5. Client measures the time taken

The scripts measure the complete request-response cycle from the client's perspective, exactly as a real user would experience it.

### What Gets Tested

The scripts test:

- Response time (how fast your server responds)
- Throughput (requests per second your server can handle)
- Reliability (success vs failure rate)
- Consistency (variance in response times)
- Latency distribution (P50, P95, P99 percentiles)

These metrics are independent of your programming language or framework.

### What Does NOT Get Tested

The scripts do not test:

- Your application's internal code quality
- Database query efficiency (only the total response time)
- Memory usage within your application
- Code-level performance bottlenecks

For internal profiling, use language-specific tools (Xdebug for PHP, node --inspect for Node.js, pprof for Go, etc.).

## Real-World Example: Multi-Technology Comparison

Here's how you might test different versions of the same API built with different technologies:

```bash
# PHP Laravel API
declare -A SCENARIOS=(
    ["PHP_API"]="http://localhost:8000/api/products"
)

# Node.js Express API
declare -A SCENARIOS=(
    ["NodeJS_API"]="http://localhost:3000/api/products"
)

# Python FastAPI
declare -A SCENARIOS=(
    ["Python_API"]="http://localhost:8001/api/products"
)

# Go API
declare -A SCENARIOS=(
    ["Go_API"]="http://localhost:8080/api/products"
)
```

Run the same test parameters against each and compare the results to see which implementation performs best for your use case.

## Conclusion

These load testing scripts provide powerful tools for measuring web application performance regardless of the underlying technology. Start with slt.sh for quick checks, and use dlt.sh for comprehensive analysis and formal reporting.

Remember that load testing is an iterative process. Run tests regularly, compare results over time, and use the insights to optimize your application's performance.

The beauty of HTTP-based testing is that you can test any web application or API regardless of how it's built, making these scripts valuable tools for any web developer or DevOps engineer.