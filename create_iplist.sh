#!/bin/sh

# functions
function usage() {
    echo "usage: $(basename $0) [-i path] [-o path] [-n address] [-d]"
    echo "          -i use file defined by path as input file for domains to resolve"
    echo "          -o use file defined by path as output file for ip-addresses"
    echo "          -n use specific dns server. default: system default"
    echo "          -d debug mode"
}

function reset() {
    if [ "$debug" = "1" ]; then echo "reset($*)"; fi
    local outfile=$1
    rm -f $outfile
    touch $outfile
}

function addspf() {
    if [ "$debug" = "1" ]; then echo "addspf($*)"; fi
    local ip=""
    local domainspf=$1
    for spf in $(dig $dnsserver $domainspf TXT +short | grep spf | tr " " "\n" | sed 's/\"//'); do
        case $spf in
            a)
                ip=$(dig $dnsserver $domainspf A +short)
                if [ "$debug" = "1" ]; then echo "adding ip: $ip"; fi
            ;;
            a:*)
                ip=$(dig $dnsserver $(dig $dnsserver $domainspf TXT +short | tr " " "\n" | grep "a\:.*" | cut -d ":" -f 2) A +short)
                if [ "$debug" = "1" ]; then echo "adding ip: $ip"; fi
            ;;
            mx)
                mx=($(dig $dnsserver $domainspf MX +short | cut -d " " -f 2))
                for key in "${!mx[@]}"; do 
                    ip="$(dig $dnsserver ${mx[$key]} A +short)"
                    if [ "$debug" = "1" ]; then echo "adding ip: $ip"; fi
                done
            ;;
            include:*) 
                addspf ${spf#include:}
             ;;
            redirect*)
                # TODO
                if [ "$debug" = "1" ]; then echo "warning: redirect SPF directive currently not supported" >&2; fi
            ;;
            ip4:*) 
                ip=${spf#ip4:}
                if [ "$debug" = "1" ]; then echo "adding ip: $ip"; fi
            ;;
            ip6:*)
                ip=${spf#ip6:}
                if [ "$debug" = "1" ]; then echo "adding ip: $ip"; fi
            ;;
        esac
        if [ "$ip" != "" ]; then echo $ip >> $ipsfile; fi 
    done
}

# main
# parse commandline options
while getopts ":i:o:n:dh" OPT; do
    case "$OPT" in
        n)
            dnsserver=$OPTARG
            dnsserver="@$dnsserver"
            ;;
        i)
            domains=$OPTARG
            ;; 
        o)
            ipsfile=$OPTARG
            ;;
        d)
            debug="1"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "error: invalid option -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done
   
# define default values: 
# input file "domains"
# output file "iplist"
# use system default nameserver
if [ "$domains" = "" ]; then domains="domains"; fi
if [ "$ipsfile" = "" ]; then ipsfile="iplist"; fi
if [ $# -eq 0 ]; then
    dnsserver=""
    domains="domains"
fi

# sanitize output file
reset $ipsfile

if ! [ -s $domains ]; then
    echo "error: domains file \"$domains\" is empty" >&2
    exit 1
fi

for domain in $(cat $domains); do
        echo "# $domain" >> $ipsfile
        addspf $domain
        echo "" >> $ipsfile
done
exit 0
