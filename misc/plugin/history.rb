=begin

== plugin/history.rb - CVS の編集履歴を表示するプラグイン

  Copyright (C) 2003 Hajime BABA <baba.hajime@nifty.com>
  $Id: history.rb,v 1.12 2004-10-31 10:45:37 fdiary Exp $
  You can redistribute and/or modify this file under the terms of the LGPL.

  Copyright (C) 2003 Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>

=== 使い方

* Hiki の cvs プラグイン (あるいは svn プラグイン) を利用している
  ことが前提条件です。

* その上で、Hiki のプラグインディレクトリにコピーすれば、
  上部メニューに「編集履歴」が現れて使えるようになります。

=== 詳細

* 以下の三つのプラグインコマンドが追加されます。
    * history       ページの編集履歴の一覧を表示
    * history_src   あるリビジョンのソースを表示
    * history_diff  任意のリビジョン間の差分を表示
  実際には、
    @conf.cgi_name?c=history;p=FrontPage や
    @conf.cgi_name?c=plugin;plugin=history_diff;p=FrontPage;r=2
  のように使用します。

* 履歴にはブランチ等が現れないことを前提にしています。

* Subversion 対応は適当です(僕が使っていないので)。

* プラグイン作成の作法がよくわかってないので、どなたか直してください。

=== history
2003/12/17 Yasuo Itabashi(Yas)    Subversion対応, 変更箇所の強調対応, Ruby 1.7以降に対応

=== notice
Hikifarmを使用している場合、hiki.confに
@conf.repos_type      = (defined? repos_type) ? "#{repos_type}" : nil
を追加してください。-- Yas

CSSでspan.add_line, span.del_lineを設定すると、変更箇所の文字属性を変更できます。
-- Yas


=== SEE ALSO

* 一覧の出力形式は WiLiKi の編集履歴を参考にさせていただきました。
  http://www.shiro.dreamhost.com/scheme/wiliki/wiliki.cgi

=end

def history_label
  '編集履歴'
end

def history
  h = Hiki::History::new(@cgi, @db, @conf)
  h.history
end

def history_src
  h = Hiki::History::new(@cgi, @db, @conf)
  h.history_src
end

def history_diff
  h = Hiki::History::new(@cgi, @db, @conf)
  h.history_diff
end

add_body_enter_proc(Proc.new do
  if @conf.repos_root then
    add_plugin_command('history', history_label, {'p' => true})
  else
    ''
  end
end)

module Hiki
  class History < Command
    private

    def history_repos_type
      @conf.repos_type # 'cvs' or 'svn'
    end

    def history_repos_root
      @conf.repos_root # hiki.conf
    end

    def history_label
      '編集履歴'
    end

    def history_th_label
      #  ['Rev', 'Time(GMT)', 'Changes', 'Operation', 'Log']
      ['Rev', '時刻(GMT)', '変更', '操作', 'ログ']
    end

    def history_not_supported_label
      '現在の設定では編集履歴はサポートされていません。'
    end

    def history_diffto_current_label
      '現在のバージョンとの差分を見る'
    end

    def history_backto_summary_label
      '編集履歴ページに戻る'
    end

    def history_add_line_label
      '+追加された行'
    end

    def history_delete_line_label
      '-削除された行'
    end

    # Subroutine to invoke external command using `` sequence.
    def history_exec_command (cmd_string)
      cmdlog = ''
      oldpwd = Dir.pwd.untaint
      begin
	Dir.chdir( "#{@conf.pages_path}" )
	# うーん... まあとりあえず。
	cmdlog = `#{cmd_string.untaint}`
      ensure
	Dir.chdir( oldpwd )
      end
      cmdlog
    end

    # Subroutine to output proper HTML for Hiki.
    def history_output (s)
      # Imported codes from hiki/command.rb::cmd_view()
      parser = ::Hiki::const_get( @conf.parser )::new( @conf )
      tokens = parser.parse( s )
      formatter = ::Hiki::const_get( @conf.formatter )::new( tokens, @db, @plugin, @conf )
      @page  = Page::new( @cgi, @conf )
      data   = Util::get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu(data, @cmd)
      pg_title = @plugin.page_name(@p)
      data[:title]      = title( "#{pg_title} - #{history_label}")
      data[:view_title] = "#{pg_title} - #{history_label}"
      data[:body]       = formatter.apply_tdiary_theme(s).sanitize

      @cmd = 'view' # important!!!
      generate_page(data) # private method inherited from Command class
    end


    public

    # Output summary of change history
    def history
      unless history_repos_root then
	return history_output(history_not_supported_label)
      end

      # make command string
      case history_repos_type
      when 'cvs'
	hstcmd = "cvs -Q -d #{history_repos_root} log #{@p.escape}"
      when 'svn'
	hstcmd = "svn log #{@p.escape}"
      else
	return history_output(history_not_supported_label)
      end

      # invoke external command
      cmdlog = history_exec_command(hstcmd)

      # parse the result and make revisions array
      revisions = Array::new()
      case history_repos_type
      when 'cvs'
        cmdlog.split(/----------------------------/).each do |tmp|
	  if /revision 1.(\d+?)\ndate: (.*?);  author: (?:.*?);  state: (?:.*?);(.*?)?\n(.*)/m =~ tmp then
	    revisions << [$1.to_i, $2, $3, $4]
	  end
	end
      when 'svn'
        diffrevs = []
        cmdlog.split(/------------------------------------------------------------------------/).each do |tmp|
          if /(?:\D+)(\d+?)[\s:\|]+[(?:\s)*](?:.*?) \| (.*?)(?: \(.+\))? \| (.*?)\n(.*?)\n/m =~ tmp then
	    revisions << [$1.to_i, $2, $3, $4]
            diffrevs << $1.to_i
	  end
	end
      end

      # construct output sources
      if history_repos_type == 'svn' then
        prevdiff = 1
      end
      sources = ''
      #  sources << "<pre>\n"
      #  sources << cmdlog
      #  sources << "</pre>\n"
      sources << "\n<table border=\"1\">\n"
      if @conf.options['history.hidelog']
	sources << " <tr><th>#{history_th_label[0].escapeHTML}</th><th>#{history_th_label[1].escapeHTML}</th><th>#{history_th_label[2].escapeHTML}</th><th>#{history_th_label[3].escapeHTML}</th></tr>\n"
      else
	sources << " <tr><th rowspan=\"2\">#{history_th_label[0].escapeHTML}</th><th>#{history_th_label[1].escapeHTML}</th><th>#{history_th_label[2].escapeHTML}</th><th>#{history_th_label[3].escapeHTML}</th></tr><tr><th colspan=\"3\">#{history_th_label[4].escapeHTML}</th></tr>\n"
      end
      revisions.each do |rev,time,changes,log|
	#    time << " GMT"
        op = "[<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_src;p=#{@p.escape};r=#{rev}")}\">View</a> this version] "
	op << "[Diff to "
        case history_repos_type
        when 'cvs'
          op << "<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_diff;p=#{@p.escape};r=#{rev}")}\">current</a>" unless revisions.size == rev
	op << " | " unless (revisions.size == rev || rev == 1)
          op << "<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_diff;p=#{@p.escape};r=#{rev};r2=#{rev-1}")}\">previous</a>" unless rev == 1
        when 'svn'
          op << "<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_diff;p=#{@p.escape};r=#{rev}")}\">current</a>" unless prevdiff == 1
          op << " | " unless (prevdiff == 1 || prevdiff >= diffrevs.size)
          op << "<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_diff;p=#{@p.escape};r=#{rev};r2=#{diffrevs[prevdiff]}")}\">previous</a>" unless prevdiff >= diffrevs.size
        end
	op << "]"
	if @conf.options['history.hidelog']
	  sources << " <tr><td>#{rev}</td><td>#{time.escapeHTML}</td><td>#{changes.escapeHTML}</td><td align=right>#{op}</td></tr>\n"
	else
	  log.gsub!(/=============================================================================/, '')
	  log.chomp!
	  log = "*** no log message ***" if log.empty?
	  sources << " <tr><td rowspan=\"2\">#{rev}</td><td>#{time.escapeHTML}</td><td>#{changes.escapeHTML}</td><td align=right>#{op}</td></tr><tr><td colspan=\"3\">#{log.escapeHTML}</td></tr>\n"
	end
        if history_repos_type == 'svn' then
          prevdiff += 1
        end
      end
      sources << "</table>\n"

      history_output(sources)
    end

    # Output source at an arbitrary revision
    def history_src
      unless history_repos_root then
	return history_output(history_not_supported_label)
      end

      # make command string
      r = @cgi.params['r'][0] || '1'
      case history_repos_type
      when 'cvs'
	hstcmd = "cvs -Q -d #{history_repos_root} update -p -r 1.#{r.to_i} #{@p.escape}"
      when 'svn'
        hstcmd = "svn cat -r #{r.to_i} #{@p.escape}"
      else
	return history_output(history_not_supported_label)
      end

      # invoke external command
      cmdlog = history_exec_command(hstcmd)
      cmdlog = "*** no source ***" if cmdlog.empty?

      # construct output sources
      sources = ''
      sources << "<div class=\"section\">\n"
      sources << "<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_diff;p=#{@p.escape};r=#{r.escapeHTML}")}\">#{history_diffto_current_label.escapeHTML}</a><br>\n"
      sources << "<a href=\"#{@conf.cgi_name}#{cmdstr('history', "p=#{@p.escape}")}\">#{history_backto_summary_label.escapeHTML}</a><br>\n"
      sources << "</div>\n"
      sources << "<pre class=\"diff\">\n"
      sources << cmdlog.escapeHTML
      sources << "</pre>\n"

      history_output(sources)
    end

    # Output diff between two arbitrary revisions
    def history_diff
      unless history_repos_root then
	return history_output(history_not_supported_label)
      end

      # make command string
      r = @cgi.params['r'][0] || '1'
      r2 = @cgi.params['r2'][0]
      case history_repos_type
      when 'cvs'
	revopt = "-r 1.#{r.to_i}"
	revopt = "-r 1.#{r2.to_i} -r 1.#{r.to_i}" unless r2.nil? || r2.to_i == 0
	hstcmd = "cvs -Q -d #{history_repos_root} diff -u #{revopt} #{@p.escape}"
      when 'svn'
        revopt = "#{r.to_i}"
        revopt = "#{r2.to_i}:#{r.to_i}" unless r2.nil? || r2.to_i == 0
        hstcmd = "svn diff -r #{revopt} #{@p.escape}"
      else
	return history_output(history_not_supported_label)
      end

      # invoke external command
      cmdlog = history_exec_command(hstcmd)
      cmdlog = '---' + cmdlog.split(/^---/)[1..-1].join('---') # Get rid of header
      cmdlog = "*** no diff ***" if cmdlog.empty?

      # construct output sources
      sources = ''
      sources << "<div class=\"section\">\n"
      sources << "<a href=\"#{@conf.cgi_name}#{cmdstr('history', "p=#{@p.escape}")}\">#{history_backto_summary_label.escapeHTML}</a><br>\n"
      sources << "</div>\n<br>\n"
      sources << "<span class=\"add_line\">#{history_add_line_label.escapeHTML}</span><br>\n"
      sources << "<span class=\"del_line\">#{history_delete_line_label.escapeHTML}</span><br>\n"
      sources << "<pre class=\"diff\">\n"
      diffsrc = cmdlog.escapeHTML
      cmdlog = nil
      diffsrc.each do |tmp|
        if /^[\+\-].*/m =~ tmp then
          if /^\+.*/m =~ tmp then
            tmp = "<span class=\"add_line\">#{tmp}<\/span>"
          elsif
            tmp = "<span class=\"del_line\">#{tmp}<\/span>"
          end
        end
        if /^[^\\].*/m =~ tmp then
          sources << "#{tmp}"
        end
      end
      sources << "</pre>\n"

      history_output(sources)
    end
  end
end

