# $Id: auth_typekey.rb,v 1.5 2005-03-17 13:43:13 fdiary Exp $
# Copyright (C) 2005 TAKEUCHI Hitoshi
#
# 

require 'hiki/auth/typekey'
require 'hiki/session'

@conf['typekey.token'] ||= ''

def auth?
  return true if @conf['typekey.token'].empty?
  session_id = @cgi.cookies['typekey_session_id'][0]
  session_id && Session::new(@conf, session_id).check
end

def auth_typekey
  tk = TypeKey.new(@conf['typekey.token'], '1.1')
  ts =    @cgi.params['ts'][0]
  email = @cgi.params['email'][0]
  name =  @cgi.params['name'][0]
  nick =  @cgi.params['nick'][0]
  sig =   @cgi.params['sig'][0]
  page =  @cgi.params['p'][0] || 'FrontPage'

  if ts and email and name and nick and sig and tk.verify(email, name, nick, ts, sig)
    session = Session::new(@conf)
    self.cookies << typekey_cookie('typekey_session_id', session.session_id)
    self.cookies << typekey_cookie('auth_name', utf8_to_euc(nick))
  end

  redirect(@cgi, "#{@conf.cgi_name}?#{page}", self.cookies)
end


def login_url
  tk = TypeKey.new(@conf['typekey.token'])
  return_url = "#{@conf.index_url}?c=plugin;plugin=auth_typekey;p=#{@page}"
  tk.getLoginUrl(return_url)
end

def typekey_cookie(name, value, max_age = Session::MAX_AGE)
  CGI::Cookie::new( {
    'name' => name,
    'value' => value,
    'path' => self.cookie_path,
  })
end

add_body_enter_proc(Proc::new do
  nick = @cgi.cookies['auth_name'][0]
  if !auth?
    label_auth_typekey_login
  elsif nick
    <<EOS
<div class="hello">
#{sprintf(label_auth_typekey_hello, nick.escapeHTML)}
</div>
EOS
  end
end)

def saveconf_auth_typekey
  if @mode == 'saveconf' then
    @conf['typekey.token'] = @cgi.params['typekey.token'][0]
  end
end

add_conf_proc('auth_typekey', label_auth_typekey_config) do
  saveconf_auth_typekey
  str = <<-HTML
  <h3 class="subtitle">#{label_auth_typekey_token}</h3>
  <p>#{label_auth_typekey_token_msg}</p>
  <p><input name="typekey.token" size="40" value="#{CGI::escapeHTML(@conf['typekey.token'])}"></p>
  HTML
  str
end
