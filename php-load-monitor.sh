#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   PHP Load Monitor v2.0.0                                                 ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Autor:   Percio Castelo                                                 ║
# ║   Contato: percio@evolya.com.br | contato@perciocastelo.com.br            ║
# ║   Web:     https://perciocastelo.com.br                                   ║
# ║                                                                           ║
# ║   Função:  Monitors PHP processes (php-fpm, lsphp, php-cgi, cli,          ║
# ║            ea-php/alt-php, sw-engine), system load and RAM usage across   ║
# ║            snapshots, generating table/JSON/CSV reports and email alerts. ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -uo pipefail
export LC_ALL=C

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SELF_PID="$$"

# =============================================================================
# Defaults
# =============================================================================
ITERATIONS=10
INTERVAL="1"
MIN_CPU="0.0"
MIN_MEM="0.0"
FILTER_USER=""
TOP_LIMIT=20
SORT_BY="cpu"
OUTPUT_FORMAT="table"
OUTPUT_FILE=""
EMAIL_TO=""
LOAD_ALERT=""
QUIET=false
NO_COLOR=false
SHOW_SNAPSHOTS=false

# Temp workspace
TMP_DIR=""
RAW_TSV=""
REPORT_TMP=""

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

# =============================================================================
# Colors (auto-disabled if non-TTY or non-table)
# =============================================================================
C_RESET=""
C_BOLD=""
C_DIM=""
C_RED=""
C_GREEN=""
C_YELLOW=""
C_BLUE=""
C_CYAN=""

init_colors() {
    if [[ "$NO_COLOR" == false && "$OUTPUT_FORMAT" == "table" && -t 1 && -z "${NO_COLOR:-}" ]]; then
        C_RESET=$'\033[0m'
        C_BOLD=$'\033[1m'
        C_DIM=$'\033[2m'
        C_RED=$'\033[0;31m'
        C_GREEN=$'\033[0;32m'
        C_YELLOW=$'\033[0;33m'
        C_BLUE=$'\033[0;34m'
        C_CYAN=$'\033[0;36m'
    fi
}

log_info()  { [[ "$QUIET" == false && "$OUTPUT_FORMAT" == "table" ]] && echo -e "${C_CYAN}[→]${C_RESET} $*" >&2; }
log_ok()    { [[ "$QUIET" == false && "$OUTPUT_FORMAT" == "table" ]] && echo -e "${C_GREEN}[+]${C_RESET} $*" >&2; }
log_warn()  { [[ "$QUIET" == false ]] && echo -e "${C_YELLOW}[!]${C_RESET} $*" >&2; }
log_err()   { echo -e "${C_RED}[✗]${C_RESET} $*" >&2; }

# =============================================================================
# Help & Version
# =============================================================================
show_help() {
    cat <<EOF
PHP Load Monitor v${VERSION}
Universal PHP process, CPU, RAM and Load Average monitor for Linux/cPanel/DirectAdmin/Hestia.

Usage:
  ${SCRIPT_NAME} [OPTIONS]
  ${SCRIPT_NAME} <EMAIL> [ITERATIONS]     (legacy positional syntax)

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

Examples:
  ${SCRIPT_NAME} -n 5 -i 0.5
  ${SCRIPT_NAME} -n 30 -i 1 -c 5.0 -o json > php-audit.json
  ${SCRIPT_NAME} -n 10 -u myuser --sort rss -o table
  ${SCRIPT_NAME} -n 20 -i 0.5 -e admin@example.com --load-alert 4.0
  ${SCRIPT_NAME} -n 5 -o csv -f /tmp/php-load.csv
EOF
}

# =============================================================================
# Argument Parsing
# =============================================================================
is_positive_int() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 > 0 ))
}

is_non_negative_int() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

is_non_negative_num() {
    [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}

parse_args() {
    local positional=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--iterations)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                ITERATIONS="$2"; shift 2 ;;
            -i|--interval)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                INTERVAL="$2"; shift 2 ;;
            -c|--min-cpu)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                MIN_CPU="$2"; shift 2 ;;
            -m|--min-mem)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                MIN_MEM="$2"; shift 2 ;;
            -u|--user)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                FILTER_USER="$2"; shift 2 ;;
            -t|--top)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                TOP_LIMIT="$2"; shift 2 ;;
            -s|--sort)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                SORT_BY="$2"; shift 2 ;;
            -o|--output)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                OUTPUT_FORMAT="$2"; shift 2 ;;
            -f|--file)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                OUTPUT_FILE="$2"; shift 2 ;;
            -e|--email)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                EMAIL_TO="$2"; shift 2 ;;
            --load-alert)
                [[ $# -lt 2 ]] && { log_err "Option $1 requires a value."; exit 1; }
                LOAD_ALERT="$2"; shift 2 ;;
            --snapshots)
                SHOW_SNAPSHOTS=true; shift ;;
            -q|--quiet)
                QUIET=true; shift ;;
            --no-color)
                NO_COLOR=true; shift ;;
            -V|--version)
                echo "PHP Load Monitor v${VERSION}"
                exit 0 ;;
            -h|-H|--help)
                show_help
                exit 0 ;;
            --)
                shift
                while [[ $# -gt 0 ]]; do positional+=("$1"); shift; done ;;
            -*)
                log_err "Unknown option: $1 (use --help for usage)"
                exit 1 ;;
            *)
                positional+=("$1"); shift ;;
        esac
    done

    # Legacy positional syntax compatibility: ./php-load-monitor.sh <EMAIL> [ITERATIONS]
    if [[ ${#positional[@]} -ge 1 ]]; then
        if [[ "${positional[0]}" == *@* ]]; then
            EMAIL_TO="${positional[0]}"
            if [[ ${#positional[@]} -ge 2 ]]; then
                ITERATIONS="${positional[1]}"
            else
                ITERATIONS=60
            fi
        else
            log_err "Invalid positional argument '${positional[0]}'. Use flags (e.g. -n 10) or legacy '<EMAIL> [ITERATIONS]'."
            exit 1
        fi
    fi

    # Validate arguments
    if ! is_positive_int "$ITERATIONS"; then
        log_err "--iterations must be a positive integer (got: $ITERATIONS)"
        exit 1
    fi
    if ! is_non_negative_num "$INTERVAL"; then
        log_err "--interval must be a non-negative number (got: $INTERVAL)"
        exit 1
    fi
    if ! is_non_negative_num "$MIN_CPU"; then
        log_err "--min-cpu must be a non-negative number (got: $MIN_CPU)"
        exit 1
    fi
    if ! is_non_negative_num "$MIN_MEM"; then
        log_err "--min-mem must be a non-negative number (got: $MIN_MEM)"
        exit 1
    fi
    if ! is_non_negative_int "$TOP_LIMIT"; then
        log_err "--top must be a non-negative integer (got: $TOP_LIMIT)"
        exit 1
    fi
    if [[ -n "$LOAD_ALERT" ]] && ! is_non_negative_num "$LOAD_ALERT"; then
        log_err "--load-alert must be a non-negative number (got: $LOAD_ALERT)"
        exit 1
    fi
    case "$SORT_BY" in
        cpu|mem|rss) ;;
        *) log_err "--sort must be one of: cpu, mem, rss (got: $SORT_BY)"; exit 1 ;;
    esac
    case "$OUTPUT_FORMAT" in
        table|json|csv) ;;
        *) log_err "--output must be one of: table, json, csv (got: $OUTPUT_FORMAT)"; exit 1 ;;
    esac
}

# =============================================================================
# System Metrics Helpers
# =============================================================================
get_primary_ip() {
    local ip=""
    if command -v ip >/dev/null 2>&1; then
        ip=$(ip -4 addr show scope global 2>/dev/null | awk '/inet / {sub(/\/.*/, "", $2); print $2; exit}')
    fi
    if [[ -z "$ip" ]] && command -v hostname >/dev/null 2>&1; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    echo "${ip:-127.0.0.1}"
}

get_cpu_cores() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    elif [[ -r /proc/cpuinfo ]]; then
        grep -c '^processor' /proc/cpuinfo
    else
        echo "1"
    fi
}

get_load_avg() {
    if [[ -r /proc/loadavg ]]; then
        awk '{printf "%s, %s, %s", $1, $2, $3}' /proc/loadavg
    else
        uptime | awk -F'load average: ' '{print $2}'
    fi
}

get_load_1m() {
    if [[ -r /proc/loadavg ]]; then
        awk '{print $1}' /proc/loadavg
    else
        uptime | awk -F'load average: ' '{split($2, a, ","); gsub(/ /, "", a[1]); print a[1]}'
    fi
}

get_mem_info() {
    # Outputs: total_mb used_mb free_mb avail_mb used_pct
    if [[ -r /proc/meminfo ]]; then
        awk '
            /^MemTotal:/     { total = $2 }
            /^MemFree:/      { free = $2 }
            /^MemAvailable:/ { avail = $2 }
            END {
                if (avail == 0) avail = free;
                used = total - avail;
                if (used < 0) used = 0;
                pct = (total > 0) ? (used * 100.0 / total) : 0;
                printf "%d %d %d %d %.1f", total/1024, used/1024, free/1024, avail/1024, pct;
            }
        ' /proc/meminfo
    elif command -v free >/dev/null 2>&1; then
        free -m | awk '/^Mem:/ {
            avail = ($7 != "") ? $7 : $4;
            used = $2 - avail;
            pct = ($2 > 0) ? (used * 100.0 / $2) : 0;
            printf "%d %d %d %d %.1f", $2, used, $4, avail, pct;
        }'
    else
        echo "0 0 0 0 0.0"
    fi
}

# =============================================================================
# Snapshot Collector
# =============================================================================
collect_snapshots() {
    local ps_sort="-pcpu"
    case "$SORT_BY" in
        mem) ps_sort="-pmem" ;;
        rss) ps_sort="-rss" ;;
        *)   ps_sort="-pcpu" ;;
    esac

    : > "$RAW_TSV"
    local i ts
    for (( i = 1; i <= ITERATIONS; i++ )); do
        ts=$(date '+%Y-%m-%d %H:%M:%S')
        # Columns emitted (tab-separated):
        # snap \t ts \t pid \t user \t pcpu \t pmem \t rss_mb \t etime \t cmd
        ps -eo pid=,ppid=,user:24=,pcpu=,pmem=,rss=,etime=,args= --sort="$ps_sort" 2>/dev/null \
            | awk -v snap="$i" \
                  -v ts="$ts" \
                  -v self_pid="$SELF_PID" \
                  -v min_cpu="$MIN_CPU" \
                  -v min_mem="$MIN_MEM" \
                  -v filter_user="$FILTER_USER" '
            {
                pid  = $1
                ppid = $2
                user = $3
                pcpu = $4 + 0
                pmem = $5 + 0
                rss_kb = $6 + 0
                etime = $7
                # Reconstruct args from field 8 onward
                cmd = ""
                for (f = 8; f <= NF; f++) {
                    cmd = (cmd == "") ? $f : (cmd " " $f)
                }
                # Exclude self and child helper processes
                if (pid == self_pid || ppid == self_pid) next
                if (cmd ~ /php-load-monitor\.sh/) next

                # Match PHP engines: php, php-fpm, php-cgi, lsphp, ea-php*, alt-php*, sw-engine
                low = tolower(cmd)
                is_php = (low ~ /(^|[\/ ])(php[0-9.\-]*|php-fpm[0-9.\-]*|php-cgi[0-9.\-]*|lsphp[0-9.\-]*|ea-php[0-9]+|alt-php[0-9]+|sw-engine)([ :\/]|$)/) || (low ~ /php-fpm:/)
                if (!is_php) next

                if (filter_user != "" && user != filter_user) next
                if (pcpu < (min_cpu + 0)) next
                if (pmem < (min_mem + 0)) next

                # Sanitize tabs/newlines in cmd
                gsub(/\t/, " ", cmd)
                rss_mb = rss_kb / 1024.0
                printf "%d\t%s\t%s\t%s\t%.1f\t%.1f\t%.1f\t%s\t%s\n", \
                    snap, ts, pid, user, pcpu, pmem, rss_mb, etime, cmd
            }' >> "$RAW_TSV"

        if (( i < ITERATIONS )); then
            sleep "$INTERVAL"
        fi
    done
}

# =============================================================================
# Report Formatters
# =============================================================================
render_table() {
    local host="$1" ip="$2" cores="$3" load_str="$4"
    local mem_total="$5" mem_used="$6" mem_avail="$7" mem_pct="$8"
    local total_rows
    total_rows=$(wc -l < "$RAW_TSV")

    echo "======================================================================================================"
    echo " PHP LOAD MONITOR v${VERSION} - [${host}] [${ip}]"
    echo "======================================================================================================"
    echo " Report Date : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo " CPU / Load  : ${cores} cores | Load Average: ${load_str}"
    echo " Memory RAM  : ${mem_used} MB / ${mem_total} MB (${mem_pct}% used, ${mem_avail} MB available)"
    echo " Sampling    : ${ITERATIONS} snapshot(s) x ${INTERVAL}s | Sort: ${SORT_BY} | Filters: CPU>=${MIN_CPU}% MEM>=${MIN_MEM}%${FILTER_USER:+ USER=${FILTER_USER}}"
    echo "======================================================================================================"

    if (( total_rows == 0 )); then
        echo ""
        echo " No matching PHP processes detected during the ${ITERATIONS} snapshot(s)."
        echo "======================================================================================================"
        return 0
    fi

    if [[ "$SHOW_SNAPSHOTS" == true ]]; then
        echo ""
        echo "--- RAW SNAPSHOTS ---"
        printf "%-4s | %-8s | %-14s | %-6s | %-6s | %-8s | %-11s | %s\n" \
            "SNAP" "PID" "USER" "%CPU" "%MEM" "RSS(MB)" "ELAPSED" "COMMAND"
        echo "------------------------------------------------------------------------------------------------------"
        awk -F'\t' '{
            cmd = (length($9) > 48) ? substr($9, 1, 45) "..." : $9
            printf "%-4s | %-8s | %-14s | %6s | %6s | %8s | %-11s | %s\n", \
                $1, $3, $4, $5, $6, $7, $8, cmd
        }' "$RAW_TSV"
    fi

    echo ""
    echo "--- TOP PHP PROCESSES (AGGREGATED ACROSS ${ITERATIONS} SNAPSHOTS) ---"
    printf "%-8s | %-14s | %-5s | %-7s | %-7s | %-8s | %-11s | %s\n" \
        "PID" "USER" "HITS" "AVG%CPU" "MAX%CPU" "MAX RSS" "ELAPSED" "COMMAND"
    echo "------------------------------------------------------------------------------------------------------"

    awk -F'\t' -v sort_by="$SORT_BY" -v top_limit="$TOP_LIMIT" '
    {
        pid = $3
        user[pid] = $4
        cpu = $5 + 0
        mem = $6 + 0
        rss = $7 + 0
        etime[pid] = $8
        cmd[pid] = $9
        hits[pid]++
        sum_cpu[pid] += cpu
        sum_mem[pid] += mem
        if (!(pid in max_cpu) || cpu > max_cpu[pid]) max_cpu[pid] = cpu
        if (!(pid in max_mem) || mem > max_mem[pid]) max_mem[pid] = mem
        if (!(pid in max_rss) || rss > max_rss[pid]) max_rss[pid] = rss
    }
    END {
        for (p in hits) {
            avg_cpu = sum_cpu[p] / hits[p]
            avg_mem = sum_mem[p] / hits[p]
            key = max_cpu[p]
            if (sort_by == "mem") key = max_mem[p]
            else if (sort_by == "rss") key = max_rss[p]
            c = (length(cmd[p]) > 46) ? substr(cmd[p], 1, 43) "..." : cmd[p]
            printf "%012.3f\t%-8s | %-14s | %5d | %7.1f | %7.1f | %6.1fMB | %-11s | %s\n", \
                key, p, user[p], hits[p], avg_cpu, max_cpu[p], max_rss[p], etime[p], c
        }
    }' "$RAW_TSV" | sort -rn | {
        if (( TOP_LIMIT > 0 )); then
            head -n "$TOP_LIMIT"
        else
            cat
        fi
    } | cut -f2-

    echo ""
    echo "--- RESOURCE SUMMARY BY USER ---"
    printf "%-16s | %-10s | %-10s | %-10s | %-10s\n" \
        "USER" "UNIQUE PID" "SAMPLES" "PEAK %CPU" "PEAK RSS"
    echo "----------------------------------------------------------------------"

    awk -F'\t' '
    {
        u = $4; p = $3; cpu = $5 + 0; rss = $7 + 0
        samples[u]++
        if (!seen[u SUBSEP p]++) uniq[u]++
        if (!(u in peak_cpu) || cpu > peak_cpu[u]) peak_cpu[u] = cpu
        if (!(u in peak_rss) || rss > peak_rss[u]) peak_rss[u] = rss
    }
    END {
        for (u in samples) {
            printf "%012.3f\t%-16s | %10d | %10d | %9.1f%% | %7.1f MB\n", \
                peak_cpu[u], u, uniq[u], samples[u], peak_cpu[u], peak_rss[u]
        }
    }' "$RAW_TSV" | sort -rn | cut -f2-

    echo "======================================================================================================"
}

render_csv() {
    echo "snapshot,timestamp,pid,user,cpu_pct,mem_pct,rss_mb,elapsed,command"
    awk -F'\t' '{
        cmd = $9
        gsub(/"/, "\"\"", cmd)
        printf "%s,\"%s\",%s,\"%s\",%s,%s,%s,\"%s\",\"%s\"\n", \
            $1, $2, $3, $4, $5, $6, $7, $8, cmd
    }' "$RAW_TSV"
}

render_json() {
    local host="$1" ip="$2" cores="$3" load_1m="$4" load_str="$5"
    local mem_total="$6" mem_used="$7" mem_avail="$8" mem_pct="$9"

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$RAW_TSV" "$VERSION" "$host" "$ip" "$cores" "$load_1m" "$load_str" \
            "$mem_total" "$mem_used" "$mem_avail" "$mem_pct" "$ITERATIONS" "$INTERVAL" "$SORT_BY" "$TOP_LIMIT" <<'PYEOF'
import json, sys, datetime

(tsv_path, version, host, ip, cores, load_1m, load_str,
 mem_total, mem_used, mem_avail, mem_pct, iterations, interval, sort_by, top_limit) = sys.argv[1:16]

procs = {}
users = {}
total_samples = 0

with open(tsv_path, encoding="utf-8") as fh:
    for line in fh:
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) < 9:
            continue
        snap, ts, pid, user, cpu, mem, rss, etime, cmd = parts[:9]
        cpu_f, mem_f, rss_f = float(cpu), float(mem), float(rss)
        total_samples += 1

        p = procs.setdefault(pid, {
            "pid": int(pid),
            "user": user,
            "hits": 0,
            "sum_cpu": 0.0,
            "max_cpu": 0.0,
            "max_mem": 0.0,
            "max_rss_mb": 0.0,
            "elapsed": etime,
            "command": cmd,
        })
        p["hits"] += 1
        p["sum_cpu"] += cpu_f
        p["max_cpu"] = max(p["max_cpu"], cpu_f)
        p["max_mem"] = max(p["max_mem"], mem_f)
        p["max_rss_mb"] = max(p["max_rss_mb"], rss_f)
        p["elapsed"] = etime

        u = users.setdefault(user, {"user": user, "pids": set(), "samples": 0, "peak_cpu": 0.0, "peak_rss_mb": 0.0})
        u["pids"].add(pid)
        u["samples"] += 1
        u["peak_cpu"] = max(u["peak_cpu"], cpu_f)
        u["peak_rss_mb"] = max(u["peak_rss_mb"], rss_f)

proc_list = []
for p in procs.values():
    proc_list.append({
        "pid": p["pid"],
        "user": p["user"],
        "hits": p["hits"],
        "avg_cpu_pct": round(p["sum_cpu"] / p["hits"], 2),
        "max_cpu_pct": round(p["max_cpu"], 2),
        "max_mem_pct": round(p["max_mem"], 2),
        "max_rss_mb": round(p["max_rss_mb"], 2),
        "elapsed": p["elapsed"],
        "command": p["command"],
    })

sort_key = {"cpu": "max_cpu_pct", "mem": "max_mem_pct", "rss": "max_rss_mb"}.get(sort_by, "max_cpu_pct")
proc_list.sort(key=lambda x: x[sort_key], reverse=True)
top_n = int(top_limit)
if top_n > 0:
    proc_list = proc_list[:top_n]

user_list = sorted(
    [
        {
            "user": u["user"],
            "unique_pids": len(u["pids"]),
            "samples": u["samples"],
            "peak_cpu_pct": round(u["peak_cpu"], 2),
            "peak_rss_mb": round(u["peak_rss_mb"], 2),
        }
        for u in users.values()
    ],
    key=lambda x: x["peak_cpu_pct"],
    reverse=True,
)

payload = {
    "version": version,
    "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "server": {
        "hostname": host,
        "ip": ip,
        "cpu_cores": int(cores),
        "load_1m": float(load_1m),
        "load_average": load_str,
        "memory_mb": {
            "total": int(mem_total),
            "used": int(mem_used),
            "available": int(mem_avail),
            "used_pct": float(mem_pct),
        },
    },
    "sampling": {
        "iterations": int(iterations),
        "interval_seconds": float(interval),
        "total_samples": total_samples,
        "unique_php_processes": len(procs),
    },
    "summary_by_user": user_list,
    "processes": proc_list,
}
print(json.dumps(payload, indent=2))
PYEOF
    else
        log_err "python3 is required for -o json output."
        exit 1
    fi
}

# =============================================================================
# Mail Delivery
# =============================================================================
send_email_report() {
    local subject="$1"
    local recipient="$2"
    local body_file="$3"

    if command -v mail >/dev/null 2>&1; then
        mail -s "$subject" "$recipient" < "$body_file"
        return $?
    elif command -v mailx >/dev/null 2>&1; then
        mailx -s "$subject" "$recipient" < "$body_file"
        return $?
    elif command -v sendmail >/dev/null 2>&1; then
        {
            echo "To: ${recipient}"
            echo "Subject: ${subject}"
            echo "Content-Type: text/plain; charset=UTF-8"
            echo ""
            cat "$body_file"
        } | sendmail -t
        return $?
    else
        return 127
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    parse_args "$@"
    init_colors

    if ! command -v ps >/dev/null 2>&1 || ! command -v awk >/dev/null 2>&1; then
        log_err "Required system utilities 'ps' and 'awk' were not found."
        exit 1
    fi

    TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/php-load-monitor.XXXXXX")
    RAW_TSV="${TMP_DIR}/samples.tsv"
    REPORT_TMP="${TMP_DIR}/report.out"

    local host ip cores load_str load_1m
    local mem_total mem_used mem_free mem_avail mem_pct

    host=$(hostname 2>/dev/null || echo "unknown")
    ip=$(get_primary_ip)
    cores=$(get_cpu_cores)
    load_str=$(get_load_avg)
    load_1m=$(get_load_1m)
    read -r mem_total mem_used mem_free mem_avail mem_pct <<< "$(get_mem_info)"

    log_info "PHP Load Monitor v${VERSION} — [${host}] [${ip}] (Load: ${load_str})"
    log_info "Collecting ${ITERATIONS} snapshot(s) every ${INTERVAL}s..."

    collect_snapshots

    case "$OUTPUT_FORMAT" in
        table)
            render_table "$host" "$ip" "$cores" "$load_str" \
                "$mem_total" "$mem_used" "$mem_avail" "$mem_pct" > "$REPORT_TMP" ;;
        csv)
            render_csv > "$REPORT_TMP" ;;
        json)
            render_json "$host" "$ip" "$cores" "$load_1m" "$load_str" \
                "$mem_total" "$mem_used" "$mem_avail" "$mem_pct" > "$REPORT_TMP" ;;
    esac

    # Save to file if requested
    if [[ -n "$OUTPUT_FILE" ]]; then
        cp "$REPORT_TMP" "$OUTPUT_FILE"
        log_ok "Report saved to: ${OUTPUT_FILE}"
    fi

    # Print to stdout unless quiet + email/file only
    if [[ -z "$OUTPUT_FILE" || "$OUTPUT_FORMAT" != "table" || "$QUIET" == false ]]; then
        cat "$REPORT_TMP"
    fi

    # Check load alert threshold
    local alert_triggered=false
    if [[ -n "$LOAD_ALERT" ]]; then
        if awk -v l="$load_1m" -v t="$LOAD_ALERT" 'BEGIN { exit !(l >= t) }'; then
            alert_triggered=true
            log_warn "Load alert triggered: 1m load (${load_1m}) >= threshold (${LOAD_ALERT})"
        else
            log_info "Load 1m (${load_1m}) below alert threshold (${LOAD_ALERT}); skipping alert."
        fi
    fi

    # Send email if configured (always if no --load-alert, or only on trigger if --load-alert is set)
    if [[ -n "$EMAIL_TO" ]]; then
        if [[ -z "$LOAD_ALERT" || "$alert_triggered" == true ]]; then
            local subj="PHP Load Monitor Report: ${host} (Load: ${load_1m})"
            if send_email_report "$subj" "$EMAIL_TO" "$REPORT_TMP"; then
                log_ok "Report emailed to: ${EMAIL_TO}"
            else
                local fallback="${OUTPUT_FILE:-./php-load-monitor-${host}-$(date +%Y%m%d_%H%M%S).txt}"
                cp "$REPORT_TMP" "$fallback"
                log_err "No mail client (mail/mailx/sendmail) succeeded. Report preserved at: ${fallback}"
                exit 1
            fi
        fi
    fi

    if [[ "$alert_triggered" == true ]]; then
        exit 2
    fi
}

main "$@"
