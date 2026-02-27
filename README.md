# PHP Load Monitor 📊

Readme: [English](README.md)

![License](https://img.shields.io/github/license/sr00t3d/cpanel-reseller-usage)
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
You can run the script directly via PHP:
```bash
php php-load-monitor.sh

```

## 🛠️ Code Structure

The script uses native Linux commands to obtain the data:

* `uptime`: To capture the processor load status.
* `free -m`: To detail memory consumption in Megabytes.
* `awk`: To filter and format the text output.

## 📚 Detailed Tutorial

For a complete step-by-step guide, check out my full article:

👉 [**Quickly check PHP LOAD.**](https://perciocastelo.com.br/blog/fast-check-load-php.html)

## License 📄

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.