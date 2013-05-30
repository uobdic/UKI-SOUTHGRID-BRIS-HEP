#!/usr/bin/env ruby
### File managed with puppet ###
## Served by:        ''
## Module:           'foreman'
## Template source:  'MODULES/foreman/templates/external_node.rb.erb'


SETTINGS = {
  :url          => "https://manage.dice.cluster",
  :puppetdir    => "/var/lib/puppet",
  :facts        => true,
  :storeconfigs => false,
  :timeout      => 3,
  # if CA is specified, remote Foreman host will be verified
  :ssl_ca       => "/var/lib/puppet/ssl/certs/ca.pem",
  # ssl_cert and key are required if require_ssl_puppetmasters is enabled in Foreman
  :ssl_cert     => "/var/lib/puppet/ssl/certs/manage.dice.cluster.pem",
  :ssl_key      => "/var/lib/puppet/ssl/private_keys/manage.dice.cluster.pem"
}

# Script usually acts as an ENC for a single host, with the certname supplied as argument
#   if 'facts' is true, the YAML facts for the host are uploaded
#   ENC output is printed and cached
#
# If --push-facts is given as the only arg, it uploads facts for all hosts and then exits.
# Useful in scenarios where the ENC isn't used.

### Do not edit below this line

def url
  SETTINGS[:url] || raise("Must provide URL - please edit file")
end

def puppetdir
  SETTINGS[:puppetdir] || raise("Must provide puppet base directory - please edit file")
end

def stat_file(certname)
  FileUtils.mkdir_p "#{puppetdir}/yaml/foreman/"
  "#{puppetdir}/yaml/foreman/#{certname}.yaml"
end

def tsecs
  SETTINGS[:timeout] || 3
end

require 'net/http'
require 'net/https'
require 'fileutils'
require 'timeout'

def upload_all_facts
  Dir["#{puppetdir}/yaml/facts/*.yaml"].each do |f|
    certname = File.basename(f, ".yaml")
    upload_facts(certname, f)
  end
end

def upload_facts(certname, filename)
  # Temp file keeping the last run time
  stat = stat_file(certname)
  last_run = File.exists?(stat) ? File.stat(stat).mtime.utc : Time.now - 365*24*60*60
  last_fact = File.stat(filename).mtime.utc
  if last_fact > last_run
    fact = File.read(filename)
    begin
      uri = URI.parse("#{url}/fact_values/create?format=yml")
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data('facts' => fact)
      res             = Net::HTTP.new(uri.host, uri.port)
      res.use_ssl     = uri.scheme == 'https'
      if res.use_ssl?
        if SETTINGS[:ssl_ca]
          res.ca_file = SETTINGS[:ssl_ca]
          res.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
          res.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        if SETTINGS[:ssl_cert] and SETTINGS[:ssl_key]
          res.cert = OpenSSL::X509::Certificate.new(File.read(SETTINGS[:ssl_cert]))
          res.key  = OpenSSL::PKey::RSA.new(File.read(SETTINGS[:ssl_key]), nil)
        end
      end
      res.start { |http| http.request(req) }
    rescue => e
      raise "Could not send facts to Foreman: #{e}"
    end
  end
end

def cache(certname, result)
  File.open(stat_file(certname), 'w') {|f| f.write(result) }
end

def read_cache(certname)
  File.read(stat_file(certname))
rescue => e
  raise "Unable to read from Cache file: #{e}"
end

def enc(certname)
  foreman_url      = "#{url}/node/#{certname}?format=yml"
  uri              = URI.parse(foreman_url)
  req              = Net::HTTP::Get.new(foreman_url)
  http             = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl     = uri.scheme == 'https'
  if http.use_ssl?
    if SETTINGS[:ssl_ca]
      http.ca_file = SETTINGS[:ssl_ca]
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    else
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    if SETTINGS[:ssl_cert] and SETTINGS[:ssl_key]
      http.cert = OpenSSL::X509::Certificate.new(File.read(SETTINGS[:ssl_cert]))
      http.key  = OpenSSL::PKey::RSA.new(File.read(SETTINGS[:ssl_key]), nil)
    end
  end
  res = http.start { |http| http.request(req) }

  raise "Error retrieving node #{certname}: #{res.class}" unless res.code == "200"
  res.body
end

# Actual code starts here
begin
  if ARGV.delete("--push-facts")
    # push all facts files to Foreman and don't act as an ENC
    upload_all_facts
  else
    certname = ARGV[0] || raise("Must provide certname as an argument")
    # send facts to Foreman - enable 'facts' setting to activate
    # if you use this option below, make sure that you don't send facts to foreman via the rake task or push facts alternatives.
    #
    if SETTINGS[:facts] && !SETTINGS[:storeconfigs]
      upload_facts certname, "#{puppetdir}/yaml/facts/#{certname}.yaml"
    end
    #
    # query External node
    begin
      result = ""
      timeout(tsecs) do
        result = enc(certname)
        cache(certname, result)
      end
    rescue TimeoutError, SocketError, Errno::EHOSTUNREACH
      # Read from cache, we got some sort of an error.
      result = read_cache(certname)
    ensure
      puts result
    end
  end
rescue => e
  warn e
  exit 1
end
