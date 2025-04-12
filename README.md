# LoveMeOrLeaveMe

A simple but effective command-line utility that monitors CPU idle time and automatically shuts down your system when it's been idle for a specified duration.

## Features

- **Customizable idle threshold**: Set the CPU idle percentage threshold that triggers the countdown
- **Flexible timing**: Configure both the check interval and the required idle duration
- **Clear feedback**: Watch real-time updates about current CPU idle status and countdown progress
- **Simple interface**: Easy-to-use command line options

## Installation

### Homebrew (recommended)

```bash
# First, tap the repository
brew tap indigoviolet/lovemeorleaveme

# Then install the formula
brew install lovemeorleaveme
```

## Usage

The command requires at least one flag to run:

```bash
lovemeorleaveme [OPTIONS]
```

### Options

```
-i, --idle-percent PERCENT   CPU idle threshold percentage (default: 95)
-t, --idle-time SECONDS      Required idle duration in seconds (default: 600)
-c, --check-interval SECONDS Interval between checks in seconds (default: 30)
-s, --shutdown               Actually perform shutdown when threshold reached
-h, --help                   Display this help message and exit
```

### Examples

Monitor with default settings (95% idle for 10 minutes) in simulation mode:
```bash
lovemeorleaveme -i 95
```

Monitor with default settings AND actually shutdown when threshold is reached:
```bash
lovemeorleaveme -i 95 -s
```

Shut down after 1 hour of at least 90% CPU idle time:
```bash
lovemeorleaveme -i 90 -t 3600
```

Check every minute, shut down after 2 hours of 98% idle time:
```bash
lovemeorleaveme -i 98 -t 7200 -c 60
```

## Requirements

- **vmstat**: Used to measure CPU idle time. On Linux, it's typically included in the procps or procps-ng package. On macOS, you may need to use the built-in vm_stat command instead.
- **gum**: Required for the pretty interface. Installed automatically when using Homebrew.
- **sudo privileges**: Required to execute the shutdown command.

## How It Works

The script monitors CPU idle percentage using `vmstat`. When the idle percentage stays above your threshold for the specified duration, it initiates a system shutdown.

## License

MIT License
