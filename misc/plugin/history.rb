=begin

== plugin/history.rb - CVS §Œ ‘Ω∏Õ˙ŒÚ§Ú…Ωº®§π§Î•◊•È•∞•§•Û

  Copyright (C) 2003 Hajime BABA <baba.hajime@nifty.com>
  $Id: history.rb,v 1.17 2005-02-08 07:20:35 fdiary Exp $
  You can redistribute and/or modify this file under the terms of the LGPL.

  Copyright (C) 2003 Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>

=== ª»§§ ˝

* Hiki §Œ cvs •◊•È•∞•§•Û (§¢§Î§§§œ svn •◊•È•∞•§•Û) §ÚÕ¯Õ—§∑§∆§§§Î
  §≥§»§¨¡∞ƒÛæÚ∑Ô§«§π°£

* §Ω§ŒæÂ§«°¢Hiki §Œ•◊•È•∞•§•Û•«•£•Ï•Ø•»•Í§À•≥•‘°º§π§Ï§–°¢
  æÂ…Ù•·•À•Â°º§À°÷ ‘Ω∏Õ˙ŒÚ°◊§¨∏Ω§Ï§∆ª»§®§Î§Ë§¶§À§ §Í§ﬁ§π°£

=== æ‹∫Ÿ

* ∞ ≤º§Œª∞§ƒ§Œ•◊•È•∞•§•Û•≥•ﬁ•Û•…§¨ƒ…≤√§µ§Ï§ﬁ§π°£
    * history       •⁄°º•∏§Œ ‘Ω∏Õ˙ŒÚ§Œ∞ÏÕ˜§Ú…Ωº®
    * history_src   §¢§Î•Í•”•∏•Á•Û§Œ•Ω°º•π§Ú…Ωº®
    * history_diff  «§∞’§Œ•Í•”•∏•Á•Û¥÷§Œ∫π ¨§Ú…Ωº®
  º¬∫›§À§œ°¢
    @conf.cgi_name?c=history;p=FrontPage §‰
    @conf.cgi_name?c=plugin;plugin=history_diff;p=FrontPage;r=2
  §Œ§Ë§¶§Àª»Õ—§∑§ﬁ§π°£

* Õ˙ŒÚ§À§œ•÷•È•Û•¡≈˘§¨∏Ω§Ï§ §§§≥§»§Ú¡∞ƒÛ§À§∑§∆§§§ﬁ§π°£

* Subversion ¬–±˛§œ≈¨≈ˆ§«§π(ÀÕ§¨ª»§√§∆§§§ §§§Œ§«)°£

* •◊•È•∞•§•Û∫Ó¿Æ§Œ∫ÓÀ°§¨§Ë§Ø§Ô§´§√§∆§ §§§Œ§«°¢§…§ §ø§´ƒæ§∑§∆§Ø§¿§µ§§°£

=== history
2003/12/17 Yasuo Itabashi(Yas)    Subversion¬–±˛,  —ππ≤’ΩÍ§Œ∂Øƒ¥¬–±˛, Ruby 1.7∞ πﬂ§À¬–±˛

=== notice
Hikifarm§Úª»Õ—§∑§∆§§§ÎæÏπÁ°¢hiki.conf§À
@conf.repos_type      = (defined? repos_type) ? "#{repos_type}" : nil
§Úƒ…≤√§∑§∆§Ø§¿§µ§§°£-- Yas

CSS§«span.add_line, span.del_line§Ú¿ﬂƒÍ§π§Î§»°¢ —ππ≤’ΩÍ§Œ ∏ª˙¬∞¿≠§Ú —ππ§«§≠§ﬁ§π°£
-- Yas


=== SEE ALSO

* ∞ÏÕ˜§ŒΩ–Œœ∑¡º∞§œ WiLiKi §Œ ‘Ω∏Õ˙ŒÚ§Úª≤πÕ§À§µ§ª§∆§§§ø§¿§≠§ﬁ§∑§ø°£
  http://www.shiro.dreamhost.com/scheme/wiliki/wiliki.cgi

=end

def history_label
  ' ‘Ω∏Õ˙ŒÚ'
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

add_body_enter_proc(Proc::new do
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
      ' ‘Ω∏Õ˙ŒÚ'
    end

    def history_th_label
      #  ['Rev', 'Time(GMT)', 'Changes', 'Operation', 'Log']
      ['Rev', 'ª˛πÔ', ' —ππ', '¡‡∫Ó', '•Ì•∞']
    end

    def history_not_supported_label
      '∏Ω∫ﬂ§Œ¿ﬂƒÍ§«§œ ‘Ω∏Õ˙ŒÚ§œ•µ•›°º•»§µ§Ï§∆§§§ﬁ§ª§Û°£'
    end

    def history_diffto_current_label
      '∏Ω∫ﬂ§Œ•–°º•∏•Á•Û§»§Œ∫π ¨§Ú∏´§Î'
    end

    def history_view_this_version_src_label
      '$B$3$N%P!<%8%g%s$N%=!<%9$r8+$k(B'
    end

    def history_backto_summary_label
      ' ‘Ω∏Õ˙ŒÚ•⁄°º•∏§ÀÃ·§Î'
    end

    def history_add_line_label
      'ƒ…≤√§µ§Ï§ø…Ù ¨§œ<ins class="added">§≥§Œ§Ë§¶§À</ins>…Ωº®§∑§ﬁ§π°£'
    end

    def history_delete_line_label
      '∫ÔΩ¸§µ§Ï§ø…Ù ¨§œ<del class="deleted">§≥§Œ§Ë§¶§À</del>…Ωº®§∑§ﬁ§π°£'
    end

    # Subroutine to invoke external command using `` sequence.
    def history_exec_command (cmd_string)
      cmdlog = ''
      oldpwd = Dir.pwd.untaint
      begin
	Dir.chdir( "#{@db.pages_path}" )
	# §¶°º§Û... §ﬁ§¢§»§Í§¢§®§∫°£
	cmdlog = `#{cmd_string.untaint}`
      ensure
	Dir.chdir( oldpwd )
      end
      cmdlog
    end

    # Subroutine to output proper HTML for Hiki.
    def history_output (s)
      # Imported codes from hiki/command.rb::cmd_view()
      parser = @conf.parser::new( @conf )
      tokens = parser.parse( s )
      formatter = @conf.formatter::new( tokens, @db, @plugin, @conf )
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

    def revisions
      # make command string
      case history_repos_type
      when 'cvs'
	hstcmd = "cvs -Q -d #{history_repos_root} log #{@p.escape}"
      when 'svn'
	hstcmd = "svn log #{@p.escape}"
      else
	raise
      end
      
      # invoke external command
      cmdlog = history_exec_command(hstcmd)
      
      # parse the result and make revisions array
      parse_history(cmdlog)
    end

    def parse_history(cmdlog)
      revs = []
      diffrevs = []
      case history_repos_type
      when 'cvs'
        cmdlog.split(/----------------------------/).each do |tmp|
	  if /revision 1.(\d+?)\ndate: (.*?);  author: (?:.*?);  state: (?:.*?);(.*?)?\n(.*)/m =~ tmp then
	    revs << [$1.to_i, Time.parse("#{$2}Z").localtime.to_s, $3, $4]
	  end
	end
      when 'svn'
        cmdlog.split(/------------------------------------------------------------------------/).each do |tmp|
          if /(?:\D+)(\d+?)[\s:\|]+[(?:\s)*](?:.*?) \| (.*?)(?: \(.+\))? \| (.*?)\n(.*?)\n/m =~ tmp then
	    revs << [$1.to_i, Time.parse("#{$2}Z").localtime.to_s, $3, $4]
            diffrevs << $1.to_i
	  end
	end
      end
      [revs, diffrevs]
    end

    def recent_revs(revs, rev)
      ind = revs.index(revs.assoc(rev)) || 0
      prev_rev = revs[ind + 1]
      prev2_rev = revs[ind + 2]
      if ind - 1 >= 0
	next_rev = revs[ind - 1]
      else
	next_rev = nil
      end
      [prev2_rev, prev_rev, revs[ind], next_rev]
    end

    def diff_link(rev1, rev2, rev_title1, rev_title2, link)
      title = []
      title << (rev_title1 || (rev1 and rev1[0]) || nil)
      title << (rev_title2 || (rev2 and rev2[0]) || nil)
      title = title.compact
      title.reverse! unless rev2.nil?
      title = title.join("<=>").escapeHTML
      
      do_link = (link and rev1)
      
      rv = "["
      if do_link
	rev_param = "r=#{rev1[0]}"
	rev_param << ";r2=#{rev2[0]}" if rev2
	rv << %Q[<a href="#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_diff;p=#{@p.escape};#{rev_param}")}" title="#{title}">]
      end
      rv << title
      if do_link
	rv << "</a>"
      end
      rv << "]\n"
      rv
    end

    public

    # Output summary of change history
    def history
      unless history_repos_root then
	return history_output(history_not_supported_label)
      end

      unless %w(cvs svn).include?(history_repos_type)
	return history_output(history_not_supported_label)
      end

      # parse the result and make revisions array
      revs, diffrevs = revisions

      # construct output sources
      if history_repos_type == 'svn' then
        prevdiff = 1
      end
      sources = ''
      #  sources << "<pre>\n"
      #  sources << cmdlog
      #  sources << "</pre>\n"
      sources << @plugin.hiki_anchor(@p.escape, @plugin.page_name(@p))
      sources << "\n<br>\n"
      sources << "\n<table border=\"1\">\n"
      if @conf.options['history.hidelog']
	sources << " <tr><th>#{history_th_label[0].escapeHTML}</th><th>#{history_th_label[1].escapeHTML}</th><th>#{history_th_label[2].escapeHTML}</th><th>#{history_th_label[3].escapeHTML}</th></tr>\n"
      else
	sources << " <tr><th rowspan=\"2\">#{history_th_label[0].escapeHTML}</th><th>#{history_th_label[1].escapeHTML}</th><th>#{history_th_label[2].escapeHTML}</th><th>#{history_th_label[3].escapeHTML}</th></tr><tr><th colspan=\"3\">#{history_th_label[4].escapeHTML}</th></tr>\n"
      end
      revs.each do |rev,time,changes,log|
	#    time << " GMT"
        op = "[<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_src;p=#{@p.escape};r=#{rev}")}\">View</a> this version] "
	op << "[Diff to "
        case history_repos_type
        when 'cvs'
          op << "<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_diff;p=#{@p.escape};r=#{rev}")}\">current</a>" unless revs.size == rev
	op << " | " unless (revs.size == rev || rev == 1)
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
	hstcmd = "cvs -Q up -p -r 1.#{r.to_i} #{@p.escape}"
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
      sources << @plugin.hiki_anchor(@p.escape, @plugin.page_name(@p))
      sources << "\n<br>\n"
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

      unless %w(cvs svn).include?(history_repos_type)
	return history_output(history_not_supported_label)
      end

      # make command string
      r = @cgi.params['r'][0] || '1'
      r2 = @cgi.params['r2'][0]
      case history_repos_type
      when 'cvs'
	if r2.nil? || r2.to_i == 0
	  new = @db.load(@p)
	  old = history_exec_command("cvs -Q up -p -r 1.#{r.to_i} #{@p.escape}")
	else
	  new = history_exec_command("cvs -Q up -p -r 1.#{r.to_i} #{@p.escape}")
	  old = history_exec_command("cvs -Q up -p -r 1.#{r2.to_i} #{@p.escape}")
	end	  
      when 'svn'
	if r2.nil? || r2.to_i == 0
	  new = @db.load(@p)
	  old = history_exec_command("svn cat -r #{r.to_i} #{@p.escape}")
	else
	  new = history_exec_command("svn cat -r #{r.to_i} #{@p.escape}")
	  old = history_exec_command("svn cat -r #{r2.to_i} #{@p.escape}")
	end	  
      else
	return history_output(history_not_supported_label)
      end

      # parse the result and make revisions array
      revs, diffrevs = revisions
			
      prev2_rev, prev_rev, curr_rev, next_rev = recent_revs(revs, r.to_i)
      last_rev = revs[0]

      diff = word_diff( old, new )

      # construct output sources
      sources = ''
      sources << "<div class=\"section\">\n"
      sources << @plugin.hiki_anchor(@p.escape, @plugin.page_name(@p))
      sources << "<br>\n"
      sources << "<a href=\"#{@conf.cgi_name}#{cmdstr('plugin', "plugin=history_src;p=#{@p.escape};r=#{curr_rev[0]}")}\">#{history_view_this_version_src_label.escapeHTML}</a><br>\n" if curr_rev
      sources << "<a href=\"#{@conf.cgi_name}#{cmdstr('history', "p=#{@p.escape}")}\">#{history_backto_summary_label.escapeHTML}</a><br>\n"
      sources << "\n"

      if prev_rev
	do_link = (last_rev and prev_rev and last_rev[0] != prev_rev[0])
	sources << diff_link(prev_rev, nil, nil, "HEAD", do_link)
      end
      if prev_rev and prev2_rev
	sources << diff_link(prev_rev, prev2_rev, nil, nil, true)
      end
      sources << diff_link(curr_rev, r2.nil? ? nil : prev_rev, nil, nil, false)
      if next_rev
	sources << diff_link(next_rev, curr_rev, nil, nil, true)
      end
      do_link = (r2 and last_rev and last_rev[0] != curr_rev[0])
      sources << diff_link(curr_rev, nil, nil, "HEAD", do_link)

      sources << "</div>\n<br>\n"
      sources << "<ul>"
      sources << "  <li>#{history_add_line_label}</li>"
      sources << "  <li>#{history_delete_line_label}</li>"
      sources << "</ul>"
      sources << "<pre class=\"diff\">#{diff}</pre>\n"

      history_output(sources)
    end
  end
end

