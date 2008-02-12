# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2. 

add_conf_proc("word_filter", WordFilterMessage.word_filter) do
  pre = "word_filter"
  key_use = "#{pre}.use"
  key_words = "#{pre}.words"

  if @cgi.request_method=="POST" and @mode=="saveconf"
    @conf[key_use] = @cgi.params[key_use][0]
    @conf[key_words] = @cgi.params[key_words][0]
  end
  old = @conf[key_words]
  @conf[key_words] ||= ""

  m = WordFilterMessage

  <<EOT
<h2>#{m.word_filter}</h2>
<input type='checkbox' name='#{key_use}' id='#{key_use}' #{@conf[key_use] ? "checked='checked'" : ""}>
<label for='#{key_use}'>#{m.use}</label>
<p>#{m.regexp_by_line}</p>
<textarea name='#{key_words}' col='80' row='40'>#{CGI.escapeHTML(@conf[key_words])}</textarea>
</ul>
EOT
end
