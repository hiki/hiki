# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2. 

require "hiki/util"
class BayesFilterConfig
  Hiki = ::Hiki
  Filter = Hiki::Filter
  BayesFilter = Hiki::Filter::BayesFilter
  include Hiki::Util
  include BayesFilter::Key

  module Mode
    SUBMITTED_PAGES = "submitted_pages"
    SUBMITTED_PAGE_DIFF = "submitted_page_diff"
    PROCESS_PAGE_DATA = "process_page_data"
    HAM_TOKENS = "ham_tokens"
    SPAM_TOKENS = "spam_tokens"
    PAGE_TOKEN = "page_token"
  end

  SubmittedPages = Struct.new(:ham, :spam, :doubt)

  def initialize(cgi, conf, mode, db)
    BayesFilter.init(conf)
    @cgi = cgi
    @conf = conf
    @confmode = mode
    @db = db
  end

  def save_mode?
    @cgi.request_method=="POST" and @confmode=="saveconf"
  end

  def html
    case @mode = @cgi.params['bfmode'][0]
    when Mode::SUBMITTED_PAGES
      r = submitted_pages_html
    when Mode::SUBMITTED_PAGE_DIFF
      r = submitted_page_diff_html
    when Mode::PROCESS_PAGE_DATA
      process_page_data
      r = top_html
    when Mode::HAM_TOKENS
      r = tokens_html(BayesFilter.db.ham.keys, Res.ham_tokens)
    when Mode::SPAM_TOKENS
      r = tokens_html(BayesFilter.db.spam.keys, Res.spam_tokens)
    when Mode::PAGE_TOKEN
      r = page_token_html
    else
      r = top_html
    end
    r = "#{@message}<hr>"+r if @message
    r
  end

  def conf_url(mode=nil)
    r = "#{@conf.cgi_name}#{cmdstr("admin", "conf=bayes_filter")}"
    r << ";bfmode=#{mode}" if mode
    r
  end

  def top_html
    selected = "selected='selected'"

    plain = "PLAIN"
    paul_graham = "Paul Graham"
    @conf[TYPE] ||= plain
    @conf[THRESHOLD] ||= 0.9

    if save_mode? and @cgi.params["from_top"][0]
      @conf[USE] = @cgi.params[USE][0]
      @conf[THRESHOLD] = (@cgi.params[THRESHOLD][0]||0.9).to_f
      @conf[REPORT] = @cgi.params[REPORT][0]

      rebuild = false
      rebuild = true if @cgi.params["rebuild_db"][0]=="execute"
      if @cgi.params[TYPE][0] && @cgi.params[TYPE][0]!=@conf[TYPE]
        @conf[TYPE] = @cgi.params[TYPE][0] 
        rebuild = true
      end

      rebuild_db if rebuild
    end

    <<EOT
<ul>
<li><a href="#{conf_url(Mode::HAM_TOKENS)}">#{Res.ham_tokens}</a></li>
<li><a href="#{conf_url(Mode::SPAM_TOKENS)}">#{Res.spam_tokens}</a></li>
<li><a href="#{conf_url(Mode::SUBMITTED_PAGES)}">#{Res.submitted_pages}</a></li>
<li><select name='#{TYPE}'>
<option #{@conf[TYPE]==plain ? selected : ""}>#{plain}</option>
<option #{@conf[TYPE]==paul_graham ? selected : ""}>#{paul_graham}</option>
</select></li>
<li><input type='checkbox' name='rebuild_db' value='execute' id='rebuild_db'><label for='rebuild_db'>#{Res.rebuild_db}</label></li>
<li><input type='text' name='#{THRESHOLD}' value='#{@conf[THRESHOLD]}' id='#{THRESHOLD}'><label for='#{THRESHOLD}'>#{Res.threshold}</label></li>
<li><input type='checkbox' name='#{USE}' value='yes' id='#{USE}' #{@conf[USE] ? "checked='checked'" : ""}><label for='#{USE}'>#{Res.use_filter}</label>
<li><input type='checkbox' name='#{REPORT}' value='yes' id='#{REPORT}' #{@conf[REPORT] ? "checked='checked'" : ""}><label for='#{REPORT}'>#{Res.report_filtering}</label>
</ul>
<input type='hidden' name='from_top' value='yes'>
EOT
  end

  def submitted_pages_html
    sp = submitted_pages
    r = ""
    {"Ham"=>sp.ham, "Doubt"=>sp.doubt, "Spam"=>sp.spam}.each do |k, h|
      next if h.empty?
      r << "<h3>#{k}</h3>\n<ul>\n"
      h.keys.sort.each do |id|
        r << <<EOT
<li><a href="?#{CGI.escape(h[id].new_page.page)}">#{CGI.escapeHTML(h[id].new_page.page)}</a>
<dl>
<dt>#{Res.title}</dt><dd>#{CGI.escapeHTML(h[id].new_page.title)}</dd>
<dt>#{Res.diff_text}</dt><dd><pre>#{CGI.escapeHTML(h[id].diff_text)}</pre></dd>
#{
  unless h[id].diff_keyword.join("\n").strip.empty?
    "<dt>#{Res.diff_keyword}</dt><dd>#{CGI.escapeHTML(h[id].diff_keyword.join("\n").strip).gsub(/\n/, "<br>")}</dd>"
  end
}
<dt>#{Res.remote_addr}</dt><dd>#{CGI.escapeHTML(h[id].new_page.remote_addr)}</dd>
#{
  rate = BayesFilter.db.estimate(h[id].token)
  rate ? "<dt>#{Res.spam_rate}</dt><dd>#{format("%.4f", rate)}</dd>" : ""
}
<dt><a href='#{conf_url(Mode::SUBMITTED_PAGE_DIFF)};id=#{id}'>#{Res.submitted_page_diff}</a></dt>
<dt><a href='#{conf_url(Mode::PAGE_TOKEN)};id=#{id}'>#{Res.token}</a></dt>
</dl>
<ul>
<li><input type='radio' id='ham_#{id}' name='register_#{id}' value='ham'><label for='ham_#{id}'>#{Res.register_as_ham}</label>
<li><input type='radio' id='spam_#{id}' name='register_#{id}' value='spam'><label for='spam_#{id}'>#{Res.register_as_spam}</label>
</ul>
<input type='hidden' name='#{id}' value="1">
</li>
EOT
      end
      r << "</ul>\n"
    end
    r << "<input type='hidden' name='bfmode' value='#{Mode::PROCESS_PAGE_DATA}'>"
    r
  end

  def submitted_pages
    r = SubmittedPages.new({}, {}, {})
    {"H"=>r.ham, "S"=>r.spam, "D"=>r.doubt}.each do |head, hash|
      prefix = "#{BayesFilter::PageData.cache_path}/#{head}"
      Dir["#{prefix}*"].each do |f|
        next unless /^#{Regexp.escape(prefix)}\d+$/=~f
        d = BayesFilter::PageData.load(f.untaint)
        hash[f[/.\d+$/]] = d if d
      end
    end
    r
  end

  def submitted_page_diff_html
    return "" unless data = BayesFilter::PageData.load_from_cache(@cgi.params["id"][0].untaint)
    <<EOT
<h3>#{Res.submitted_page_diff}</h3>
<dl>
<dt>#{Res.old_text}</dt>
<dd><pre>#{CGI.escapeHTML(data.old_page.text||"")}</pre></dd>
<dt>#{Res.new_text}</dt>
<dd><pre>#{CGI.escapeHTML(data.new_page.text||"")}</pre></dd>
</dl>
EOT
  end

  def page_token_html
    return "" unless data = BayesFilter::PageData.load_from_cache(@cgi.params["id"][0].untaint)
    <<EOT
<h3>#{Res.page_token}</h3>
#{tokens_html(data.token)}
EOT
  end

  def add_ham(token)
    db = BayesFilter.db
    db.ham << token
    db.ham << token until db.estimate(token) and db.estimate(token)<=BayesFilter.threshold
    @db_update = true
  end

  def add_spam(token)
    db = BayesFilter.db
    db.spam << token
    db.spam << token until db.estimate(token) and db.estimate(token)>BayesFilter.threshold
    @db_update = true
  end

  def save_db
    BayesFilter.db.save if @db_update
    @db_update = false
  end

  def process_page_data
    return unless save_mode?

    @cgi.params.keys.select{|k| k=~/\A[HSD]\d+\z/}.each do |id|
      data = BayesFilter::PageData.load_from_cache(id.dup.untaint, true)
      next unless data
      case @cgi.params["register_#{id}"][0]
      when "ham"
        add_ham(data.token)
        data.corpus_save(true)
      when "spam"
        add_spam(data.token)
        data.corpus_save(false)
      end
    end
    save_db
    @message = Res.success_process_page_data
  end

  def tokens_html(token, title=nil)
    db = BayesFilter.db
    scores = token.uniq.map{|t|
      [t, db.score(t)]
    }.sort{ |a, b|
      sa = a[1]||1.1
      sb = b[1]||1.1
      sa==sb ? a[0]<=>b[0] : sb<=>sa
    }
    normal = []
    addr = []
    url = []
    scores.each do |i|
      case i[0]
      when /^A (.*)$/
        addr << [$1, i[1]]
      when /^U (.*)$/
        url << [$1, i[1]]
      else
        normal << i
      end
    end
    sub = lambda do |subtitle, list|
      break "" if list.empty?
      sr = <<EOT
<h4>#{subtitle}</h4>
<table>
<tr>
<th>#{Res.token}</th><th>#{Res.score}</th>
</tr>
EOT
      list.each do |i|
        sr << <<EOT
<tr>
<td>#{i[0]}</td>
<td>#{i[1] ? format("%.4f", i[1]) : "DOUBT"}</td>
</tr>
EOT
      end
      sr << "</table>"
    end
    r = title ? "<h3>#{title}</h3>" : ""
    {Res.remote_addr=>addr, "URL"=>url, Res.other=>normal}.each do |subtitle, list|
      r << sub.call(subtitle, list)
    end
    r
  end

  def rebuild_db
    db = BayesFilter.new_db
    db.ham.clear
    db.spam.clear
    @db.pages.each do |page|
      text = @db.load(page)
      title = @db.get_attribute(page, :title) || ""
      title = page if title.empty?
      keyword = @db.get_attribute(page, :keyword) || []
      add_ham(BayesFilter::PageData.new(Filter::PageData.new(page, text, title, keyword)).token)
    end

    ["S", "H"].each do |prefix|
      Dir["#{BayesFilter::PageData.corpus_path}/#{prefix}*"].each do |f|
        next unless f=~/\/[SH]\d+\z/
        token = BayesFilter::PageData.load(f.untaint).token
        case prefix
        when "S"
          add_spam(token)
        when "H"
          add_ham(token)
        else
          "must not happen"
        end
      end
    end
    db.save
  end
end

if self.is_a?(::Hiki::Plugin)
  add_conf_proc( "bayes_filter",  BayesFilterConfig::Res.label) do
    begin
      BayesFilterConfig.new(@cgi, @conf, @mode, @db).html
    rescue
      <<EOT
<pre>
#{$!.class.name}
#{$!.message}
#{$!.backtrace.join("\n")}
</pre>
EOT
    end
  end
end
