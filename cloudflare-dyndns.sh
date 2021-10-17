#!/bin/sh

### Variables

CONFIG_FILE="$(dirname "$0")/$(basename -- "$0" .sh).ini"
INTERVAL="5"
COUNTER="10"

# stable base URL for all Version 4 HTTPS endpoints
API_ENDPOINT="https://api.cloudflare.com/client/v4"
# custom API-Token (not global API-Key)
# following permissions needed: #dns_records:edit
API_TOKEN=$(cat "${CONFIG_FILE}" | grep -E "^API_TOKEN=" | head -1 | cut -d "=" -f2)
# when you want to update "www.example.com", "www" is the RECORD_NAME and "example.com" is the ZONE_NAME
ZONE_NAME=$(cat "${CONFIG_FILE}" | grep -E "^ZONE_NAME=" | head -1 | cut -d "=" -f2)
# multiple record names separated by space, e.g. "www mail smtp"
RECORD_NAME_V4=""
RECORD_NAME_V6=""
TTL="1"
PROXIED="false"

#------------------------------------------------------------------------------#
### Functions

links_IPv4()
{
    IPv4="$(links -dump http://checkip.dyndns.org/   | tr -s '[ :]' '\n' | egrep '[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+')"
    #IPv4="1.1.1.1"
}

links_IPv6()
{
    IPv6="$(links -dump http://checkipv6.dyndns.org/ | tr -s ' ' '\n' | egrep '[0-9a-f]+[:]+[0-9a-f]+[:]*')"
    #IPv6="2606:4700:4700::1111"
}

#------------------------------------------------------------------------------#
### Get IPs

COUNTER_V4="${COUNTER}"
COUNTER_V6="${COUNTER}"

links_IPv4
while [ "x${IPv4}" = "x" -a "${COUNTER_V4}" -gt "0" ]
do
    echo -n '.'
    COUNTER_V4="$(echo "${COUNTER_V4}"|awk '{print $1-1}')"
    sleep ${INTERVAL}
    links_IPv4
done

echo

links_IPv6
while [ "x${IPv6}" = "x" -a "${COUNTER_V6}" -gt "0" ]
do
    echo -n '.'
    COUNTER_V6="$(echo "${COUNTER_V6}"|awk '{print $1-1}')"
    sleep ${INTERVAL}
    links_IPv6
done

#==============================================================================#
### Get ZONE_ID

echo
echo "#==============================================================================#"

ZONE_ID="$(curl -X GET "${API_ENDPOINT}/zones" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select(.name == \"${ZONE_NAME}\") | .id")"
echo
echo "1. ZONE_NAME='${ZONE_NAME}'"
echo "2. ZONE_ID='${ZONE_ID}'"

#------------------------------------------------------------------------------#
### IPv4

### Get RECORD_ID for ZONE_NAME
RECORD_ID="$(curl -X GET "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select((.name == \"${ZONE_NAME}\") and (.type == \"A\")) | .id")"
echo
echo "3. RECORD_ID='${RECORD_ID}'"

### Set IPv4
curl -X PUT "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"${ZONE_NAME}\",\"content\":\"${IPv4}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"
echo

#------------------------------------------------------------------------------#
### IPv4 - RECORD_NAME

for RECORD_NAME in ${RECORD_NAME_V4}
do
    ### Get RECORD_ID for ZONE_NAME
    RECORD_ID="$(curl -X GET "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select((.name == \"${RECORD_NAME}.${ZONE_NAME}\") and (.type == \"A\")) | .id")"
    echo
    echo "4. RECORD_NAME.ZONE_NAME='${RECORD_NAME}.${ZONE_NAME}'"
    echo "5. RECORD_ID='${RECORD_ID}'"

    ### Set IPv4
    curl -X PUT "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}.${ZONE_NAME}\",\"content\":\"${IPv4}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"
    echo
done

#------------------------------------------------------------------------------#
### IPv6

### Get RECORD_ID for ZONE_NAME
RECORD_ID="$(curl -X GET "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select((.name == \"${ZONE_NAME}\") and (.type == \"AAAA\")) | .id")"
echo
echo "6. RECORD_ID='${RECORD_ID}'"

### Set IPv6
curl -X PUT "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "{\"type\":\"AAAA\",\"name\":\"${ZONE_NAME}\",\"content\":\"${IPv6}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"
echo

#------------------------------------------------------------------------------#
### IPv6 - RECORD_NAME

for RECORD_NAME in ${RECORD_NAME_V6}
do
    ### Get RECORD_ID for ZONE_NAME
    RECORD_ID="$(curl -X GET "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null | jq -r ".result[] | select((.name == \"${RECORD_NAME}.${ZONE_NAME}\") and (.type == \"AAAA\")) | .id")"
    echo
    echo "7. RECORD_NAME.ZONE_NAME='${RECORD_NAME}.${ZONE_NAME}'"
    echo "8. RECORD_ID='${RECORD_ID}'"

    ### Set IPv6
    curl -X PUT "${API_ENDPOINT}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" --data "{\"type\":\"AAAA\",\"name\":\"${RECORD_NAME}.${ZONE_NAME}\",\"content\":\"${IPv6}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"
    echo
done

#==============================================================================#
