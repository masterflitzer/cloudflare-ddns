# cloudflare-ddns
Simple DDNS Shell Script for the DNS provider Cloudflare

## Dependencies

* links (Browser)
* [jq](https://github.com/stedolan/jq.git)

## Crontab

```
@reboot root cloudflare-ddns.sh > /var/log/cloudflare-ddns.log 2>&1
@hourly root cloudflare-ddns.sh > /var/log/cloudflare-ddns.log 2>&1
```
