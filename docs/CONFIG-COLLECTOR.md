# Collect configuration for review

On the FreeBSD server, as root:

```sh
sh collect-nginx-config.sh xdevs.com
```

It prints the path of one `nginx-config-xdevs.com-*.tar.gz` archive, mode 600.
Send that archive privately for analysis. The script is at
`scripts/collect-nginx-config.sh` in this repository.

Collected: effective NGINX configuration and includes, build/module information,
listening ports and sockets, process names, enabled services, web service settings,
package versions, resource samples and PHP-FPM pool configuration where present.

No installs, reloads, service changes or HTTP probes. `nginx -T` tests the
configuration, can resolve upstream names and open log/key files. Actual key/certificate files,
password files, application files, website content and access/error logs are not copied.
Credential-like lines and PHP pool environment assignments are redacted on a
best-effort basis. The archive still contains private configuration and topology;
review it before sharing. Redacted reports are for analysis, not installation.

For an alternate service configuration, use the matching path and optional prefix:

```sh
env NGINX_CONF=/path/nginx.conf NGINX_PREFIX=/path/prefix/ sh collect-nginx-config.sh xdevs.com
```

Each command's status is in `check-status.tsv`. A failed configuration test may
leave the effective configuration incomplete. No PHP or Python dependency is required.
