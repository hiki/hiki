# footnote.rb $Revision: 1.10 $
#
# fn: 脚注plugin
#   パラメタ:
#     text: 脚注本文
#     mark: 脚注マーク('*')
#
# Copyright (c) 2001,2002 Junichiro KITA <kita@kitaj.no-ip.com>
# Distributed under the GPL
#
=begin ChangeLog
2005-09-05 Kouhei Yanagita <yanagi@shakenbu.org>
        * support a block element argument (patch by U.Nakamura).

2002-05-06 MUTOH Masao <mutoh@highway.ne.jp>
        * change file encoding from ISO-2022-JP to EUC-JP.

2002-03-12 TADA Tadashi <sho@spc.gr.jp>
        * runable in secure mode.
=end

# initialize instance variable as taint
@footnote_name = ""
@footnote_name.taint
@footnote_url = ""
@footnote_url.taint
@footnote_mark_name = ""
@footnote_mark_name.taint
@footnote_mark_url = ""
@footnote_mark_url.taint
@footnotes = []
@footnotes.taint
@footnote_index = [0]
@footnote_index.taint

def fn(text, mark = '*')
        if @footnote_name
                @footnote_index[0] += 1
                @footnotes << [@footnote_index[0], text, mark]
                %Q|<span class="footnote"><a name="#{@footnote_mark_name % @footnote_index[0]}" href="#{@footnote_url % @footnote_index[0]}" title="#{text}">#{mark}#{@footnote_index[0]}</a></span>|
        else
                 ""
        end
end

def render( text )
        tmp = @conf.use_plugin
        @conf.use_plugin = false
        parser = @conf.parser::new( @conf )
        tokens = parser.parse( text.unescapeHTML )
        formatter = @conf.formatter::new( tokens, @db, self, @conf )
        @conf.use_plugin = tmp
        formatter.to_s.gsub(/\A<p>/,'').gsub(/<\/p>\Z/,'').gsub(/<p>/, '<p class="footnote">')
end

if @options['command'] == 'view'
        add_body_enter_proc(Proc::new do |date|
                date = date.strftime("%Y%m%d")
                @footnote_name.replace "f%02d"
                @footnote_url.replace "#{@index}#{anchor date}##{@footnote_name}"
                @footnote_mark_name.replace "fm%02d"
                @footnote_mark_url.replace "#{@index}#{anchor date}##{@footnote_mark_name}"
                @footnotes.clear
                @footnote_index[0] = 0
                ""
        end)
        
        add_body_leave_proc(Proc::new do |date|
                if @footnote_name and @footnotes.size > 0
                        %Q|<div class="footnote">\n| +
                        @footnotes.collect do |fn|
                                %Q|  <p class="footnote"><a name="#{@footnote_name % fn[0]}" href="#{@footnote_mark_url % fn[0]}">#{fn[2]}#{fn[0]}</a>&nbsp;#{render(fn[1])}</p>|
                        end.join("\n") +
                        %Q|\n</div>\n|
                else
                        ""
                end
        end)
end

export_plugin_methods(:fn)
