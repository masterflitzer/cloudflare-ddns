# cloudflare-dyndns
Simple DynDNS Shell Script for the DNS provider Cloudflare

## Dependencies

* links (Browser)
* [jq](https://github.com/stedolan/jq.git)

## Crontab

```
@hourly root cloudflare-dyndns.sh > /var/log/cloudflare-dyndns.log 2>&1
```
or
```
0 * * * * root cloudflare-dyndns.sh > /var/log/cloudflare-dyndns.log 2>&1
```
