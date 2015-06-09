# bind-restapi

This is a fork of ajclark/bind-restapi Sinatra app.  I have added the ability to control CNAMES, and form to manage DNS names via a browser.  In my implementation I have also utalized apache with passenger to handle communication over ssl as well as basic user authentication.  I will add the instructions on how to set that up as well.  Since i'm using basic authentaication I no loner needed the X-Api-Key header.

A quick and simple RESTful API to BIND, written in Ruby / Sinatra. Provides the ability to add/remove entries with an existing BIND DNS architecture.

I wrote this as a solution to enable our internal Cloud to add/remove machines to DNS by integrating with the DNS architecture that we have today.

## Instructions
    # cd etc/
    # named -c named.conf
    $ ruby dns.rb

### Add 'A' record to DNS:

    $ curl -v -k -u myuser:mypass -X POST -H 'Content-Type: application/json' -d '{ "hostname": "myhost1.example.com", "ip": "1.1.1.12" }' https://dnsmaster.example.com/dns

### Remove 'A' record from DNS:

    $ curl -v -k -u myuser:mypass -X DELETE -H 'Content-Type: application/json' -d '{ "hostname": "myhost1.example.com", "ip": "1.1.1.12" }' https://dnsmaster.example.com/dns

### Add 'CNAME' record to DNS:

   $ curl -v -k -u myuser:mypass -X POST -H 'Content-Type: application/json' -d '{ "hostname": "myhost1.example.com", "alias": "cname-myhost1.example.com" }' https://dnsmaster.example.com/cname

### Remove 'CNAME' record from DNS:

   $ curl -v -k -u myuser:mypass -X DELETE -H 'Content-Type: application/json' -d '{ "hostname": "myhost1.example.com", "alias": "cname-myhost1.example.com" }' https://dnsmaster.example.com/cname

## API
The API supports POST and DELETE methods to add and remove entries, respectively. On a successful POST a 201 is returned. On a successful DELETE a 200 is returned. Duplicate records are never created.

The API can reside on a local *or* remote DNS server.

On a POST request, the API adds **both** the *forward* zone **and** *reverse* in-addr.arpa zone entry as a convenience. 

On a DELETE request, the API removes **both** the *forward* zone **and** *reverse* in-addr.arpa zone entry as a connivence. 

The TTL and other DNS params are hard-coded inside of <code>dns.rb</code>

## Security
I am using apache and passenger and using an SSL connection.  I am also using apache basic authentication for login.  It will also display the username in the httpd access log so you can audit when people make changes

## etc
Example named configuration files are included to help get started with integrating <code>dns.rb</code> with BIND.
