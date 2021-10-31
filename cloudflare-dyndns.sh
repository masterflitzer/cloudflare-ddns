#!/bin/bash

##### Variables

CONFIG_FILE="$(dirname "$0")/$(basename -- "$0" .sh).ini"
INTERVAL="5"
COUNTER="10"

# multiple record names (subdomains) separated by space, e.g. "www mail smtp"
RECORD_NAME_V4=""
RECORD_NAME_V6=""
TTL="1"
PROXIED="false"

# stable base URL for all Version 4 HTTPS endpoints
API_ENDPOINT="https://api.cloudflare.com/client/v4"

# custom API-Token (not global API-Key)
# permissions needed: #dns_records:edit
API_TOKEN="$(cat "${CONFIG_FILE}" | grep -E "^API_TOKEN=" | head -1 | cut -d "=" -f2)"

# when you want to update "www.example.com", "www" is the RECORD_NAME and "example.com" is the ZONE_NAME
ZONE_NAME="$(cat "${CONFIG_FILE}" | grep -E "^ZONE_NAME=" | head -1 | cut -d "=" -f2)"

COUNTER_V4="${COUNTER}"
COUNTER_V6="${COUNTER}"


##### Functions

links_IPv4() {
    IP_V4="$(links -dump http://checkip.dyndns.org/ | tr -s '[ :]' '\n' | egrep '[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+')"
    #IPv4="1.1.1.1"
}

links_IPv6() {
    IP_V6="$(links -dump http://checkipv6.dyndns.org/ | tr -s ' ' '\n' | egrep '[0-9a-f]+[:]+[0-9a-f]+[:]*')"
    #IPv6="2606:4700:4700::1111"
}


##### Script

### Get IPs
printf "\n#==============================================================================#\n\n"

echo -n "Determining IPv4 address"
links_IPv4
while test -z "${IP_V4}" -a "${COUNTER_V4}" -gt "0"
do
    echo -n '.'
    COUNTER_V4="$(echo "${COUNTER_V4}"|awk '{print $1-1}')"
    sleep ${INTERVAL}
    links_IPv4
done
echo

echo -n "Determining IPv6 address"
links_IPv6
while test -z "${IP_V6}" -a "${COUNTER_V6}" -gt "0"
do
    echo -n '.'
    COUNTER_V6="$(echo "${COUNTER_V6}"|awk '{print $1-1}')"
    sleep ${INTERVAL}
    links_IPv6
done
echo

echo "IPv4: ${IP_V4}"
echo "IPv6: ${IP_V6}"

printf "\n#==============================================================================#\n\n"

### Get Zone ID
ZONE_ID="$(curl -X GET "${API_ENDPOINT}/zones" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select(.name == \"${ZONE_NAME}\") | .id")"

### Get Record ID (IPv4)
RECORD_ID_V4="$(curl -X GET "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select((.name == \"${ZONE_NAME}\") and (.type == \"A\")) | .id")"

### Get Record ID (IPv6)
RECORD_ID_V6="$(curl -X GET "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select((.name == \"${ZONE_NAME}\") and (.type == \"AAAA\")) | .id")"

echo "Record Name      = ${ZONE_NAME}"
echo "ZONE_ID          = ${ZONE_ID}"
echo "Record ID (IPv4) = ${RECORD_ID_V4}"
echo "Record ID (IPv6) = ${RECORD_ID_V6}"


### Set IP
printf "\n#==============================================================================#\n\n"

echo "IPv4: Updating DNS Record to '${IP_V4}'"
curl -X PUT "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records/${RECORD_ID_V4}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"${ZONE_NAME}\",\"content\":\"${IP_V4}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"; echo

printf "\n#------------------------------------------------------------------------------#\n\n"

echo "IPv6: Updating DNS Record to '${IP_V6}'"
curl -X PUT "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records/${RECORD_ID_V6}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "{\"type\":\"AAAA\",\"name\":\"${ZONE_NAME}\",\"content\":\"${IP_V6}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"; echo


### Set IP for Record Names
printf "\n#==============================================================================#\n\n"

if test ! -z "${RECORD_NAME_V4// }"; then printf "IPv4: Subdomains\n\n"; fi

COUNTER="0"
for RECORD_NAME in $RECORD_NAME_V4
do
    if test $COUNTER -gt 0; then printf "\n#------------------------------------------------------------------------------#\n\n"; fi

    RECORD_ID="$(curl -X GET "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select((.name == \"${RECORD_NAME}.${ZONE_NAME}\") and (.type == \"A\")) | .id")"

    echo "Record Name      = ${RECORD_NAME}.${ZONE_NAME}"
    echo "Record ID        = ${RECORD_ID}"

    echo "Updating DNS Record to '${IP_V4}'"
    curl -X PUT "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}.${ZONE_NAME}\",\"content\":\"${IP_V4}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"; echo

    let "COUNTER += 1"
done

if test $COUNTER -gt 0; then
    printf "#==============================================================================#\n\n"
fi

if test ! -z "${RECORD_NAME_V6// }"; then printf "IPv6: Subdomains\n\n"; fi

COUNTER="0"
for RECORD_NAME in $RECORD_NAME_V6
do
    if test $COUNTER -gt 0; then printf "\n#------------------------------------------------------------------------------#\n\n"; fi

    RECORD_ID="$(curl -X GET "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select((.name == \"${RECORD_NAME}.${ZONE_NAME}\") and (.type == \"AAAA\")) | .id")"

    echo "Record Name      = ${RECORD_NAME}.${ZONE_NAME}"
    echo "Record ID        = ${RECORD_ID}"

    echo "Updating DNS Record to '${IP_V6}'"
    curl -X PUT "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "{\"type\":\"AAAA\",\"name\":\"${RECORD_NAME}.${ZONE_NAME}\",\"content\":\"${IP_V6}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"; echo

    let "COUNTER += 1"
done

if test $COUNTER -gt 0; then
    printf "#==============================================================================#\n\n"
fi
