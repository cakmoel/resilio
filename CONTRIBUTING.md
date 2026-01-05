# Contribution Guidelines

We are excited that you want to contribute to the Resilio. To maintain the integrity of our performance metrics and the reliability of our scripts, please follow these guidelines.

Code Quality Standards As this is a performance tool, code efficiency is paramount. All shell scripts must be compatible with POSIX standards where possible or explicitly documented if requiring Bash-specific features. Ensure your code is linted using ShellCheck.

Statistical Integrity If you are modifying the mathematical logic in dlt.sh (such as confidence intervals or percentile calculations), you must provide a reference to the academic paper or industry standard justifying the change.

## Process

Fork the repository.

Create a branch for your feature or bug fix.

Submit a Pull Request with a clear explanation of how the change affects test accuracy or speed.

Ensure the README.md is updated if new flags or environment variables are introduced.