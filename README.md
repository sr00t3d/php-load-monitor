# PHP Load Monitor 📊

Readme: [BR](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/php-load-monitor)
![Shell Script](https://img.shields.io/badge/shell-script-green)

<img width="700" src="php-load-monitor-cover.webp" />

A minimalist and efficient script to monitor system load (Load Average) and RAM usage in real time, combining the agility of Shell Script with the ease of display provided by PHP.

## 🚀 How it works

The project consists of a main script (`php-load-monitor.sh`) that extracts vital information from the operating system and formats it for display. It is ideal for quick performance checks without the need to install complex monitoring tools or databases.

### Monitored information:

* **Load Average:** 1, 5, and 15-minute load averages (via `uptime`).
* **RAM Memory:** Total, used, and free usage (via `free -m`).

## 📋 Prerequisites

* Linux/Unix Operating System.
* PHP installed (for execution via CLI or web server).
* Execution permissions on the shell script.

## 🔧 Installation and Usage

1. **Clone the repository:**

```bash
git clone https://github.com/sr00t3d/php-load-monitor.git
cd php-load-monitor
```

2. **Grant execution permission to the script:**

```bash
chmod +x php-load-monitor.sh
```

3. **Execution:**

Execute script:

```bash
bash php-load-monitor.sh MAIL TOTAL 
```

Example:

```bash
----------------------------------------------------------------
 SERVER LOAD MONITOR - [hostname] [IP]
----------------------------------------------------------------
Current Server Load: 0.22, 0.21, 0.12
Starting monitoring for 5 iterations...
A report will be sent to: mail@domain.com
Please wait...
Monitoring complete. Email sent.
```

Results:

```bash
Report Date: Fri Feb 27 03:28:09 PM -03 2026
Server: vps-e168e4b3.vps.ovh.ca (51.79.52.232)
---------------------------------------------------------------------------------------------
PID      | USER         | SCRIPT/COMMAND                                     | %CPU  | TIME      
---------------------------------------------------------------------------------------------
3753898  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:41
3754428  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:33
3754663  | root         | php-fpm: master process (/opt/cpanel/ea-php81/root | 0.0   | 7-17:48:28
3998068  | root         | php-fpm: master process (/usr/local/cpanel/etc/php | 0.0   | 3-17:49:24
- Snapshot 1 of 5
3753898  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:42
3754428  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:34
3754663  | root         | php-fpm: master process (/opt/cpanel/ea-php81/root | 0.0   | 7-17:48:29
3998068  | root         | php-fpm: master process (/usr/local/cpanel/etc/php | 0.0   | 3-17:49:25
- Snapshot 2 of 5
3753898  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:42
3754428  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:34
3754663  | root         | php-fpm: master process (/opt/cpanel/ea-php81/root | 0.0   | 7-17:48:29
3998068  | root         | php-fpm: master process (/usr/local/cpanel/etc/php | 0.0   | 3-17:49:25
- Snapshot 3 of 5
3753898  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:43
3754428  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:35
3754663  | root         | php-fpm: master process (/opt/cpanel/ea-php81/root | 0.0   | 7-17:48:30
3998068  | root         | php-fpm: master process (/usr/local/cpanel/etc/php | 0.0   | 3-17:49:26
- Snapshot 4 of 5
3753898  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:43
3754428  | wp-tool+     | /usr/bin/sw-engine /usr/local/cpanel/3rdparty/wp-t | 0.0   | 7-17:48:35
3754663  | root         | php-fpm: master process (/opt/cpanel/ea-php81/root | 0.0   | 7-17:48:30
3998068  | root         | php-fpm: master process (/usr/local/cpanel/etc/php | 0.0   | 3-17:49:26
- Snapshot 5 of 5
```

## 🛠️ Code Structure

The script uses native Linux commands to obtain the data:

* `uptime`: To capture the processor load status.
* `free -m`: To detail memory consumption in Megabytes.
* `awk`: To filter and format the text output.

## ⚠️ Legal Notice

> [!WARNING]
> This software is provided "as is." Always ensure you have explicit permission before executing it. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## 📚 Detailed Tutorial

For a complete, step-by-step guide, check out my full article:

👉 [**Quickly check PHP LOAD.**](https://perciocastelo.com.br/blog/fast-check-load-php.html)

## License 📄

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.