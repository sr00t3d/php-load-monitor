# PHP Load Monitor

Readme: [EN](README.md)

![License](https://img.shields.io/github/license/sr00t3d/php-load-monitor) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg)

<img width="700" alt="PHP Load Monitor" src="php-load-monitor-cover.webp" />

Uma ferramenta de diagnóstico em Bash moderna e sem dependências pesadas para SysAdmins Linux e equipes de hospedagem (cPanel/WHM, DirectAdmin, HestiaPanel ou servidores dedicados) monitorarem processos PHP (`php-fpm`, `lsphp`, `php-cgi`, `ea-php*`, `alt-php*`, `sw-engine`, CLI), Load Average e consumo de RAM em múltiplos snapshots, identificando rapidamente os maiores ofensores de CPU e memória.

## Funcionalidades (v2.0.0)

* **Detecção Universal de Motores PHP:** Identifica automaticamente `php-fpm`, `lsphp` (LiteSpeed/CloudLinux), `php-cgi`, `ea-php*`, `alt-php*`, `sw-engine` e scripts CLI, excluindo o próprio PID do monitor.
* **Resumo Agregado de Ofensores:** Calcula número de aparições (`HITS`), média de `%CPU`, pico de `%CPU` e pico de `RSS (MB)` ao longo de todos os snapshots, além de um **Resumo por Usuário** ideal para servidores compartilhados.
* **Saída Estruturada (`-o table|json|csv`):** Tabela formatada no terminal, CSV compatível com RFC-4180 e JSON pronto para Zabbix, Prometheus, SIEMs ou abertura de chamados.
* **Filtros e Ordenação Granulares:** Filtre por `--min-cpu`, `--min-mem`, `--user`, limite resultados com `--top` e ordene por `cpu`, `mem` ou `rss`.
* **Alerta por Threshold (`--load-alert`):** Dispara e-mail (e retorna exit code `2`) somente quando o Load Average de 1 minuto atingir o limite definido — ideal para monitoramento via `cron`.
* **Arquivos Temporários Seguros e Fallback de E-mail:** Usa `mktemp` com limpeza automática via `trap`, tenta `mail` -> `mailx` -> `sendmail` e preserva o relatório em disco caso nenhum MTA esteja disponível.
* **Compatibilidade Legada:** Mantém suporte à sintaxe posicional antiga `./php-load-monitor.sh admin@exemplo.com 10`.

## Pré-requisitos

* `bash` 4.0+
* `ps`, `awk`, `sort` (presentes por padrão no Linux)
* `python3` (opcional; necessário apenas para `-o json`)
* `mail` / `mailx` / `sendmail` (opcional; necessário apenas ao usar `-e, --email`)

## Uso e Opções

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

## Exemplos Práticos

**Diagnóstico rápido no terminal (5 snapshots com intervalo de 0.5s):**
```bash
./php-load-monitor.sh -n 5 -i 0.5
```

**Exportar JSON estruturado filtrando processos acima de 5% de CPU:**
```bash
./php-load-monitor.sh -n 20 -i 1 -c 5.0 -o json > php-audit.json
```

**Auditar um usuário cPanel específico ordenado por consumo de memória RSS:**
```bash
./php-load-monitor.sh -n 10 -u cliente01 --sort rss
```

**Watchdog via cron enviando e-mail apenas se o Load 1m >= 4.0:**
```bash
./php-load-monitor.sh -n 15 -i 1 -e ops@exemplo.com.br --load-alert 4.0 -q
```

**Salvar snapshots brutos em CSV:**
```bash
./php-load-monitor.sh -n 10 -i 0.5 -o csv -f /tmp/php-load.csv
```

## Exemplo de Saída Real

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

## Tutorial Detalhado

Confira o guia completo no blog: [**Verificar rapidamente LOAD do PHP**](https://perciocastelo.com.br/blog/fast-check-load-php.html)

## Licença

Este projeto é distribuído sob a licença [Apache License 2.0](LICENSE).

---
Autor: **Percio Castelo**  
Contato: [contato@perciocastelo.com.br](mailto:contato@perciocastelo.com.br)  
Website: [https://perciocastelo.com.br](https://perciocastelo.com.br)
