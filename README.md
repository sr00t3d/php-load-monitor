# PHP Load Monitor

Readme: [PT-BR](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/php-load-monitor) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg)

<img width="700" alt="PHP Load Monitor" src="php-load-monitor-cover.webp" />

A modern, zero-dependency Bash diagnostic tool for Linux sysadmins and hosting teams (cPanel/WHM, DirectAdmin, HestiaPanel, Plesk, or standalone servers) to sample PHP processes (`php-fpm`, `lsphp`, `php-cgi`, `ea-php*`, `alt-php*`, `sw-engine`, CLI), system Load Average, and RAM usage across multiple snapshots and identify top CPU/RAM offenders in seconds.

## Features (v2.0.0)

* **Universal PHP Engine Detection:** Automatically detects `php-fpm`, `lsphp` (LiteSpeed/CloudLinux), `php-cgi`, `ea-php*`, `alt-php*`, `sw-engine`, and CLI workers while excluding its own monitor PID.
* **Aggregated Offender Summary:** Computes per-PID hits, average `%CPU`, peak `%CPU`, and peak `RSS (MB)` across all snapshots, plus a **Per-User Resource Breakdown** ideal for shared hosting environments.
* **Structured Output (`-o table|json|csv`):** Native terminal tables, RFC-4180 CSV, and structured JSON ready for Zabbix, Prometheus, SIEMs, or incident tickets.
* **Granular Filtering & Sorting:** Filter by `--min-cpu`, `--min-mem`, `--user`, limit output with `--top`, and sort by `cpu`, `mem`, or `rss`.
* **Threshold Alerting (`--load-alert`):** Only dispatches email alerts (and exits with code `2`) when the 1-minute Load Average crosses your threshold — ideal for cron-based watchdogs.
* **Safe Temp Handling & Mail Fallbacks:** Uses `mktemp` with `trap` cleanup, falls back across `mail` -> `mailx` -> `sendmail`, and preserves the report on disk if no MTA is available.
* **Backward Compatible:** Still supports the legacy positional invocation `./php-load-monitor.sh admin@example.com 10`.

## Prerequisites

* `bash` 4.0+
* `ps`, `awk`, `sort` (standard Linux coreutils/procps)
* `python3` (optional, required only for `-o json`)
* `mail` / `mailx` / `sendmail` (optional, required only when using `-e, --email`)

## Usage & Options

```text
PHP Load Monitor v2.0.0
Universal PHP process, CPU, RAM and Load Average monitor for Linux/cPanel/DirectAdmin/Hestia.

Usage:
  php-load-monitor.sh [OPTIONS]
  php-load-monitor.sh <EMAIL> [ITERATIONS]     (legacy positional syntax)

Sampling Options:
  -n, --iterations NUM    Number of snapshots to collect (default: 10)
  -i, --interval SEC      Delay between snapshots in seconds, e.g. 0.5 or 2 (default: 1)
  -c, --min-cpu PCT       Minimum %CPU threshold to include a process (default: 0.0)
  -m, --min-mem PCT       Minimum %MEM threshold to include a process (default: 0.0)
  -u, --user USER         Filter PHP processes by Linux/cPanel username
  -t, --top NUM           Max processes shown in summary (default: 20, 0 = all)
  -s, --sort FIELD        Sort order: cpu (default), mem, rss

Output & Alerting Options:
  -o, --output FORMAT     Output format: table (default), json, csv
  -f, --file PATH         Save report to the specified file path
  -e, --email ADDRESS     Send report to email via mail/mailx/sendmail
      --load-alert NUM    Only send email (and exit code 2) if 1m load >= NUM
      --snapshots         Include every raw snapshot block in table output
  -q, --quiet             Suppress banner and progress messages
      --no-color          Disable ANSI colors
  -V, --version           Show version and exit
  -h, --help              Show this help message and exit
```

## Practical Examples

**Quick interactive check (5 snapshots, 0.5s interval):**
```bash
./php-load-monitor.sh -n 5 -i 0.5
```

**Export structured JSON filtering processes above 5% CPU:**
```bash
./php-load-monitor.sh -n 20 -i 1 -c 5.0 -o json > php-audit.json
```

**Inspect a specific cPanel user sorted by peak RSS memory:**
```bash
./php-load-monitor.sh -n 10 -u myuser --sort rss
```

**Cron watchdog that emails only when 1-minute load >= 4.0:**
```bash
./php-load-monitor.sh -n 15 -i 1 -e ops@example.com --load-alert 4.0 -q
```

**Export raw snapshots to CSV file:**
```bash
./php-load-monitor.sh -n 10 -i 0.5 -o csv -f /tmp/php-load.csv
```

## Real Output Example

```text
======================================================================================================
 PHP LOAD MONITOR v2.0.0 - [cpanel-test.local] [172.20.0.2]
======================================================================================================
 Report Date : 2026-11-19 22:49:47 -03
 CPU / Load  : 6 cores | Load Average: 0.26, 0.22, 0.22
 Memory RAM  : 3079 MB / 11688 MB (26.3% used, 8609 MB available)
 Sampling    : 3 snapshot(s) x 0.5s | Sort: cpu | Filters: CPU>=0.0% MEM>=0.0%
======================================================================================================

--- TOP PHP PROCESSES (AGGREGATED ACROSS 3 SNAPSHOTS) ---
PID      | USER           | HITS  | AVG%CPU | MAX%CPU | MAX RSS  | ELAPSED     | COMMAND
------------------------------------------------------------------------------------------------------
20957    | root           |     3 |    75.8 |   101.0 |   23.8MB | 00:02       | /opt/cpanel/ea-php82/root/usr/bin/php -r $t...
20958    | root           |     3 |     8.3 |    10.0 |   23.9MB | 00:02       | /opt/cpanel/ea-php82/root/usr/bin/php -r sl...

--- RESOURCE SUMMARY BY USER ---
USER             | UNIQUE PID | SAMPLES    | PEAK %CPU  | PEAK RSS  
----------------------------------------------------------------------
root             |          2 |          6 |     101.0% |    23.9 MB
======================================================================================================
```

## Detailed Tutorial

Read the full walkthrough: [**Fast Check PHP Load**](https://perciocastelo.com.br/blog/fast-check-load-php.html)

## License

This project is licensed under the [Apache License 2.0](LICENSE).

---
Author: **Percio Castelo**  
Contact: [contato@perciocastelo.com.br](mailto:contato@perciocastelo.com.br)  
Website: [https://perciocastelo.com.br](https://perciocastelo.com.br)
