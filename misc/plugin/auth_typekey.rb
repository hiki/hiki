# $Id: auth_typekey.rb,v 1.1 2005-03-05 15:24:28 hitoshi Exp $
# Copyright (C) 2005 TAKEUCHI Hitoshi
#
# 

require 'hiki/auth/typekey'
require 'hiki/session'

def auth_typekey_label
<<EOS
<div class="hello">
ページを編集するには<a href="#{login_url}">ログイン</a>が必要です。
</div>
EOS
end

def auth_typekey_hello
	"こんにちは。%sさん"
end

def auth?
  session_id = @cgi.cookies['typekey_session_id'][0]
  session_id && Session::new(@conf, session_id).check
end

def auth_typekey
  tk = TypeKey.new(@conf['typekey.token'], '1.1')
  ts =    @cgi.params["ts"][0]
  email = @cgi.params["email"][0]
  name =  @cgi.params["name"][0]
  nick =  @cgi.params["nick"][0]
  sig =   @cgi.params["sig"][0]

  if ts and email and name and nick and sig and tk.verify(email, name, nick, ts, sig)
    session = Session::new(@conf)
    self.cookies << typekey_cookie('typekey_session_id', session.session_id)
    self.cookies << typekey_cookie('auth_name', utf8_to_euc(nick))
  end

  redirect(@cgi, @conf.cgi_name, self.cookies)
end


def login_url
  tk = TypeKey.new(@conf['typekey.token'])
  return_url = "#{@conf.index_url}?c=plugin;plugin=auth_typekey"
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
  if auth? and nick
    <<EOS
<div class="hello">
#{sprintf(auth_typekey_hello, nick.escapeHTML)}
</div>
EOS
  else
    auth_typekey_label
  end
end)

