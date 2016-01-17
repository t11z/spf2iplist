# spf2iplist
little script to create ip-address list from DNS TXT records used for Sender Policy Framework

## Requirements

* dig

## Limitations

* No validation whatsoever. If a nameserver administrator is announcing broken SPF-TXT records, it will likely break your iplist.
* Currently prefixes are only supported in ip4 or ip6 directives
* Currently redirect SPF directive is not supported. 

## Usage
Simply add domains to *domains*, one by line. For example:

    echo netflix.com >> domains
    echo amazon.com >> domains
    echo google.com >> domains
  
Then run the *create_iplist.sh* script.

    usage: create_iplist.sh [-i path] [-o path] [-n address] [-d]
          -i use file defined by path as input file for domains to resolve
          -o use file defined by path as output file for ip-addresses
          -n use specific dns server. default: system default
          -d debug mode

## Use Cases
### Greylist Exception for OpenBSD's spamd
I use this script in a cronjob to maintain a whitelist for OpenBSDs spamd, so that sending mailservers from specific domains won't be redirected to spamd but instead talk to the real mail server process on my mail server.

**/etc/pf.conf**

    table <spamd-white> persist
    table <spamd-user-white> persist file "/opt/spf/iplist"
    # forward whitelisted mailservers to smtpd
    # redirect spam deferral daemon
    no rdr on $ext_if proto tcp from <spamd-white> to any port smtp
    no rdr on $ext_if proto tcp from <spamd-user-white> to any port smtp
    rdr pass on $ext_if proto tcp from any to any port smtp -> 127.0.0.1 port spamd
