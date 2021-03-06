#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'json'
require 'ipaddr'

set :bind, '0.0.0.0'

# curl -X POST -H 'Content-Type: application/json' -H 'X-Api-Key: secret' -d '{ "hostname": "host12.apple.com", "ip": "1.1.1.12" }' http://localhost:4567/dns
# curl -X DELETE -H 'Content-Type: application/json' -H 'X-Api-Key: secret' -d '{ "hostname": "host12.apple.com", "ip": "1.1.1.12" }' http://localhost:4567/dns
# curl -X POST -H 'Content-Type: application/json' -H 'X-Api-Key: secret' -d '{ "hostname": "host12.apple.com", "alias": "alias.apple.com" }' http://localhost:4567/cname

dns_params = {
  :server => '127.0.0.1',
  :rndc_key => 'rndc-key',
  :rndc_secret => 'MHGIj19UPT5EmWeHWFJLOw==',
  :ttl => '300'
}

# Reverse the IP address for the in-addr.arpa zone
def reverse_ip(ipaddress)
  reverse_ip = IPAddr.new ipaddress
  reverse_ip.reverse
end

# Create a audit log
def my_logger
  @my_logger ||= Logger.new("/var/log/bind-restapi/request.log")
end

# Authenticate all requests with an API key
#before do
  # X-Api-Key
#  error 401 unless env['HTTP_X_API_KEY'] =~ /secret/
#end

helpers do
  def common_addA (dns_params, request_params)
    reverse_zone = reverse_ip(request_params["ip"])
    ttl = if request_params["ttl"].nil? then dns_params[:ttl] else request_params["ttl"] end

    # Add record to forward and reverse zones, via TCP
    IO.popen("nsupdate -y #{dns_params[:rndc_key]}:#{dns_params[:rndc_secret]} -v", 'r+') do |f|
      f << <<-EOF
        server #{dns_params[:server]}
        update add #{request_params["hostname"]} #{ttl} A #{request_params["ip"]}
        send
        update add #{reverse_zone} #{ttl} PTR #{request_params["hostname"]}
        send
      EOF
      f.close_write
    end
    if $? != 0 then
      status 500
    else
      status 201
    end
    my_logger.info "User: #{env['HTTP_AUTHUSER']} Status: #{status} Request: add #{request_params["hostname"]} #{ttl} A #{request_params["ip"]}"
  end

  def common_deleteA (dns_params, request_params)
    reverse_zone = reverse_ip(request_params["ip"])

    # Remove record from forward and reverse zones, via TCP
    IO.popen("nsupdate -y #{dns_params[:rndc_key]}:#{dns_params[:rndc_secret]} -v", 'r+') do |f|
      f << <<-EOF
        server #{dns_params[:server]}
        update delete #{request_params["hostname"]} A
        send
        update delete #{reverse_zone} PTR
        send
      EOF
      f.close_write
    end
    if $? != 0 then
      status 500
    end
    my_logger.info "User: #{env['HTTP_AUTHUSER']} Status: #{status} Request: delete #{request_params["hostname"]} A"
    my_logger.info "User: #{env['HTTP_AUTHUSER']} Status: #{status} Request: delete #{reverse_zone} PTR"
  end

  def common_addCNAME (dns_params, request_params)
    ttl = if request_params["ttl"].nil? then dns_params[:ttl] else request_params["ttl"] end

    # Add CNAME to zones, via TCP
    IO.popen("nsupdate -y #{dns_params[:rndc_key]}:#{dns_params[:rndc_secret]} -v", 'r+') do |f|
      f << <<-EOF
        server #{dns_params[:server]}
        update add #{request_params["alias"]}. #{ttl} cname #{request_params["hostname"]}
        send
      EOF
      f.close_write
    end
    if $? != 0 then
      status 500
    else
      status 201
    end
    my_logger.info "User: #{env['HTTP_AUTHUSER']} Status: #{status} Request: add #{request_params["alias"]}. #{ttl} cname #{request_params["hostname"]}"
  end

  def common_deleteCNAME (dns_params, request_params)
    # Remove CNAME record zone, via TCP
    IO.popen("nsupdate -y #{dns_params[:rndc_key]}:#{dns_params[:rndc_secret]} -v", 'r+') do |f|
      f << <<-EOF
        server #{dns_params[:server]}
        update delete #{request_params["alias"]} cname
        send
      EOF
      f.close_write
    end
    if $? != 0 then
      status 500
    end
  my_logger.info "User: #{env['HTTP_AUTHUSER']} Status: #{status} Request: delete #{request_params["alias"]} cname"
  end
end

get '/dnsform' do
  erb :dnsform
end

post '/dnsformA' do
  request_params = JSON.parse(params.to_json)
  if request_params["action"] == "Add" then
    common_addA dns_params, request_params
  elsif request_params["action"] == "Delete" then
    common_deleteA dns_params, request_params
  end
 "Status Code #{status} Returned"
end

post '/dnsformCNAME' do
  request_params = JSON.parse(params.to_json)
  if request_params["action"] == "Add" then
    common_addCNAME dns_params, request_params
  elsif request_params["action"] == "Delete" then
    common_deleteCNAME dns_params, request_params
  end
 "Status Code #{status} Returned"
end

get '/dnsformQuery' do
  content_type :txt
  #"#{`dig @#{params['server']} #{params['hostname']}`}"
  "#{`host #{params['hostname']} #{params['server']}`}"
end

# Manage A Records
post '/dns' do
  request_params = JSON.parse(request.body.read)
  common_addA dns_params, request_params
end

delete '/dns' do
  request_params = JSON.parse(request.body.read)
  common_deleteA dns_params, request_params
end

# Manage Cnames
post '/cname' do
  request_params = JSON.parse(request.body.read)
  common_addCNAME dns_params, request_params
end

delete '/cname' do
  request_params = JSON.parse(request.body.read)
  common_deleteCNAME dns_params, request_params
end
