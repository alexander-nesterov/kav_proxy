## KAV-Proxy

Task: checking the traffic with antivirus software (ICAP)

ICAP specification: https://tools.ietf.org/html/rfc3507

I think there are two options for solving this task
- Development of the module for nginx - **need a lot of time**
- Squid (client -> nginx -> squid -> kav -> backend) - **need little time**

I choose the second option

squid configuration file:
```bash
#---------------------------------------------------------
#Squid
#---------------------------------------------------------
http_port 5230 accel defaultsite=192.168.1.20 vhost
cache_peer 192.168.1.20 parent 5230 0 no-query
 
http_access allow all
 
http_port 3128
 
error_log_languages on
error_default_language ru
error_directory /etc/squid/share/squid-langpack/ru
 
logfile_daemon /var/log/squid/log_file_daemon
mime_table /etc/squid/mime.conf
icon_directory /etc/squid/icons
coredump_dir /var/spool/squid
unlinkd_program /etc/squid/lib/squid
 
#---------------------------------------------------------
#Kaspersky Anti-Virus
#---------------------------------------------------------
icap_enable on
icap_send_client_ip on
 
icap_service is_kav_resp respmod_precache 0 icap://127.0.0.1:1344/av/respmod
icap_service is_kav_req reqmod_precache 0 icap://127.0.0.1:1344/av/reqmod
adaptation_access is_kav_req allow all
adaptation_access is_kav_resp allow all
```

nginx location:
```bash
location ~* /test {
                access_log /var/log/nginx/test/test.access.log  log;
                proxy_bind 192.168.1.10;
                proxy_pass http://localhost:5230;
}
```

to clear headers, you need to write in nginx.conf:
```bash
more_clear_headers 'Via';
more_clear_headers 'X-Cache';
more_clear_headers 'X-Cache-Lookup';
```




