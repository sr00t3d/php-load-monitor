# PHP Load Monitor 📊

Readme: [EN](README.md)

![License](https://img.shields.io/github/license/sr00t3d/php-load-monitor)
![Shell Script](https://img.shields.io/badge/shell-script-green)

<img width="700" src="php-load-monitor-cover.webp" />

Um script minimalista e eficiente para monitorar a carga do sistema (Load Average) e o uso de memória RAM em tempo real, combinando a agilidade do Shell Script com a facilidade de exibição do PHP.

## 🚀 Como funciona

O projeto consiste em um script principal (`php-load-monitor.sh`) que extrai informações vitais do sistema operacional e as formata para exibição. Ele é ideal para verificações rápidas de performance sem a necessidade de instalar ferramentas complexas de monitoramento ou bancos de dados.

### Informações monitoradas:

* **Load Average:** Médias de carga de 1, 5 e 15 minutos (via `uptime`).
* **Memória RAM:** Uso total, usado e livre (via `free -m`).

## 📋 Pré-requisitos

* Sistema Operacional Linux/Unix.
* PHP instalado (para execução via CLI ou servidor web).
* Permissões de execução no script shell.

## 🔧 Instalação e Uso

1. **Clone o repositório:**

```bash
git clone https://github.com/sr00t3d/php-load-monitor.git
cd php-load-monitor
```

2. **Dê permissão de execução ao script:**

```bash
chmod +x php-load-monitor.sh
```

3. **Execução:**

Execute o script:

```bash
bash php-load-monitor.sh EMAIL TOTAL 
```

Exemplo:

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

Resultados:

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

## 🛠️ Estrutura do Código

O script utiliza comandos nativos do Linux para obter os dados:

* `uptime`: Para capturar o estado de carga do processador.
* `free -m`: Para detalhar o consumo de memória em Megabytes.
* `awk`: Para filtrar e formatar a saída de texto.

## ⚠️ Aviso Legal

> [!WARNING]
> Este software é fornecido "tal como está". Certifique-se sempre de ter permissão explícita antes de executar. O autor não se responsabiliza por qualquer uso indevido, consequências legais ou impacto nos dados causados ​​por esta ferramenta.

## 📚 Detailed Tutorial

Para um guia completo, passo a passo, confira meu artigo completo:

👉 [**Verificar rapidamente LOAD do PHP.**](https://perciocastelo.com.br/blog/fast-check-load-php.html)

## Licença 📄

Este projeto está licenciado sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.