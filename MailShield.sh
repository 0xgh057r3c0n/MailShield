#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

help () {
    echo -e "Accepted parameters:\n"
    echo -e "Use -d along with a domain name, example: ./MailShield.sh -d domain.com"
    echo -e "Null strings will be detected and ignored.\n"
    echo -e "Use -f along with a file containing domain names, example: ./MailShield.sh -f domains.txt"
    echo -e "Ensure the file path provided is valid."
}

check_url () {
    domain="$1"

    if [[ -z "$domain" ]]; then
        echo -e "${RED}Error:${NC} Domain name is empty or invalid."
        return 1
    fi

    retval=0
    output=$(nslookup -type=txt _dmarc."$domain" 2>/dev/null)

    if echo "$output" | grep -E "v=DMARC1.*;.*p\s*=\s*reject\b" >/dev/null; then
        echo -e "$domain is ${GREEN}NOT vulnerable${NC}"
    elif echo "$output" | grep -E "v=DMARC1.*;.*p\s*=\s*quarantine\b" >/dev/null; then
        echo -e "$domain ${YELLOW}can be vulnerable${NC} (email will be sent to spam)"
    elif echo "$output" | grep -E "v=DMARC1.*;.*p\s*=\s*none\b" >/dev/null; then
        echo -e "$domain is ${RED}vulnerable${NC}"
        retval=1
    else
        echo -e "$domain is ${RED}vulnerable${NC} (No DMARC record found)"
        retval=1
    fi
    return $retval
}

check_file () {
    input="$1"

    if [[ ! -f "$input" ]]; then
        echo -e "${RED}Error:${NC} File '$input' does not exist."
        return 1
    fi

    COUNTER=0
    VULNERABLES=0
    while IFS= read -r line; do
        domain=$(echo "$line" | xargs) # Strip leading/trailing spaces
        if [[ -n "$domain" ]]; then
            COUNTER=$((COUNTER+1))
            check_url "$domain"
            VULNERABLES=$((VULNERABLES+$?))
        fi
    done < "$input"

    echo -e "\n$VULNERABLES out of $COUNTER domains are ${RED}vulnerable${NC}."
}

main () {
    while getopts d:f: flag; do
        case "${flag}" in
            d) domain=${OPTARG};;
            f) file=${OPTARG};;
            *) help; exit 1;;
        esac
    done

    if [[ -n "$domain" ]]; then
        check_url "$domain"
    elif [[ -n "$file" ]]; then
        check_file "$file"
    else
        help
    fi
}

# Banner
echo -e "


   _____         .__.__    _________.__    .__       .__       .___
  /     \ _____  |__|  |  /   _____/|  |__ |__| ____ |  |    __| _/
 /  \ /  \\__  \ |  |  |  \_____  \ |  |  \|  |/ __ \|  |   / __ | 
/    Y    \/ __ \|  |  |__/        \|   Y  \  \  ___/|  |__/ /_/ | 
\____|__  (____  /__|____/_______  /|___|  /__|\___  >____/\____ | 
        \/     \/                \/      \/        \/           \/   by 0xgh057r3c0n

Emphasizing protection against email spoofing.
"

if [[ $# -lt 2 ]]; then
    echo -e "${RED}Error:${NC} Incorrect usage.\n"
    help
    exit 1
fi

main "$@"
