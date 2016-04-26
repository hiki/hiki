#!/bin/env ruby
# Copyright (C) 2005 jouno <jouno2002@yahoo.co.jp>
# License under GPL-2
#
# original is Adam Bregenzer(<adam@bregenzer.net>)'s python version
# http://adam.bregenzer.net/python/typekey/TypeKey.py
#
# note:
# nick name field must be sent as utf-8 url_encoded string.
#
# 2005-03-05 use CGI.escape instead of URI.escape by TAKEUCHI Hitoshi <hitoshi@namaraii.com>
#
# sample code:
=begin
token="your_site_token"
tk = TypeKey.new(token,'1.1')
if request.params['tk'] == "1"
  ts    = request.params["ts"]
  email = request.params["email"]
  name  = request.params["name"]
  nick  = request.params["nick"]
  sig   = request.params["sig"]
  if tk.verify(email, name, nick, ts, sig)
    puts "verify!"
  else
    puts "not!"
  end
end
return_url = "http://localhost/cgi-bin/tk_test.cgi"

url_sign_in = tk.getLoginUrl(return_url + "?tk=1")
url_sign_out = tk.getLogoutUrl(return_url)

puts "<a href=\"#{url_sign_in}\">sign in</a><br />";
puts "<a href=\"#{url_sign_out}\">sign out</a><br />";
=end

require "uri"
require "cgi" unless Object.const_defined?(:Rack)
require "open-uri"
require "base64"
require "openssl"

class TypeKey
    """This class handles TypeKey logins.
    """

  attr_accessor(:base_url,:key_url,:key_cache_path,:key_cache_timeout,:login_timeout)

  def initialize(token, version = "1.1")
    # Base url for generating login and logout urls.
    @base_url = "https://www.typekey.com/t/typekey/"

    # Url used to download the public key.
    @key_url = "http://www.typekey.com/extras/regkeys.txt"

    # Location for caching the public key.
    @key_cache_path = "/tmp/tk_key_cache"

    # Length of time to wait before refreshing the public key cache, in seconds.
    # Defaults to two days.
    @key_cache_timeout = 60 * 60 * 48

    # Length of time logins remain valid, in seconds.
    # Defaults to five minutes.
    @login_timeout = 60 * 5

    @token = token
    @version = version
  end

  def verify(email, name, nick, ts, sig, key = nil)
        """Verify a typekey login
        """
    # sig isn't urlencoded.
    sig.gsub!(/ /,"+")
    unless key
      key = getKey()
    end

    if @version == "1.1"
      message =[email, name, nick, ts.to_s, @token].join("::")
    else
      message =[email, name, nick, ts.to_s].join("::")
    end

    if dsaVerify(message, sig, key)
      if (Time.now.to_i - ts.to_i) > @login_timeout
        return false
      end
      return true
    else
      return false
    end

  end

  def getLoginUrl(return_url, email = false)
        """Return a URL to login to TypeKey
        """
    if email
      email = "&need_email=1"
    else
      email = ""
    end
    url  = @base_url
    url += "login?t=" + @token
    url += email
    url += "&v=" + @version
    url += "&_return=" + Hiki::Util.escape(return_url)
    return url
  end

  def getLogoutUrl(return_url)
        """Return a URL to logout of TypeKey
        """
    return @base_url + "logout?_return=" + URI.escape(return_url)
  end

  def getKey(url = nil)
        """Return the TypeKey public keys, cache results unless a url is passed
        """
    unless url
      begin
        mod_time = File.mtime(@key_cache_path).to_i
      rescue SystemCallError
        mod_time = 0
      end

      if (Time.now.to_i - mod_time) < @key_cache_timeout
        File.open(@key_cache_path, "r") {|fh|
          @key_string = fh.read
        }
      else
        open(@key_url) {|fh|
          @key_string = fh.read
        }

        File.open(@key_cache_path, "w") {|fh|
          fh.puts(@key_string)
        }

      end
    else
      open(url) {|fh|
        @key_string = fh.read
      }
    end
    tk_key = {}
    for pair in @key_string.strip.split(" ")
      key, value = pair.split("=")
      tk_key[key] = value.to_i
    end
    return tk_key

  end

  def dsaVerify(message, sig, key)
        """Verify a DSA signature
        """
    r_sig, s_sig = sig.split(":")
    r_sig = Base64.decode64(r_sig).unpack("H*")[0].hex
    s_sig = Base64.decode64(s_sig).unpack("H*")[0].hex

    sign = OpenSSL::ASN1::Sequence.new(
    [OpenSSL::ASN1::Integer.new(r_sig),
    OpenSSL::ASN1::Integer.new(s_sig)]
    ).to_der

    dsa = OpenSSL::PKey::DSA.new
    dsa.p = key["p"]
    dsa.q = key["q"]
    dsa.g = key["g"]
    dsa.pub_key = key["pub_key"]
    dss1 = OpenSSL::Digest::DSS1.new
    return dsa.verify(dss1, sign, message)
  end
end

