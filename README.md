# cloudflare-dyndns
Simple DynDNS Shell Script for Cloudflare

## Dependencies

* links (Browser)
* [jq](https://github.com/stedolan/jq.git)

## Crontab

0    *    *    *    *    root    cloudflare-dyndns.sh > /var/log/cloudflare-dyndns.log 2>&1
