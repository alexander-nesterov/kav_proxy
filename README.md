## KAV-Proxy

Task: checking the traffic with antivirus software (ICAP)

ICAP specification: https://tools.ietf.org/html/rfc3507

I think there are two options for solving this task
- Development of the module for nginx - **need a lot of time**
- Squid (client -> nginx -> squid -> kav -> backend) - **need little time**

I choose the second option

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




