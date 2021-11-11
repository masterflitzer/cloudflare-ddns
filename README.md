# cloudflare-dyndns
Simple DynDNS Shell Script for the DNS provider Cloudflare

## Dependencies

* links (Browser)
* [jq](https://github.com/stedolan/jq.git)

## Crontab

```
@reboot root cloudflare-dyndns.sh > /var/log/cloudflare-dyndns.log 2>&1
@hourly root cloudflare-dyndns.sh > /var/log/cloudflare-dyndns.log 2>&1
```
