# ajaxsearch.rb $Revision: 1.1 $
# Copyright (C) 2005 Michitaka Ohno <elpeo@mars.dti.ne.jp>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

def search
	as = Hiki::AjaxSearch.new( @cgi, @db, @conf )
	@cgi.params['key'][0] ? as.search : as.form
end

module Hiki
	class AjaxConfig
		include Messages if defined?( Messages )
		def cgi_name; $cgi_name end
		def hilight_keys; $hilight_keys end
		def lang; $lang end
	end

	class AjaxSearch < Command
		def self.label
			'Ajax¸¡º÷'
		end

		def initialize( cgi, db, conf )
			begin
				super( cgi, db, conf )
			rescue Exception
				super( cgi, db )
				@conf = AjaxConfig.new
			end
		end

		def form
			begin
				data = get_common_data( @db, @plugin, @conf )
			rescue Exception
				data = get_common_data( @db, @plugin )
			end
			@plugin.hiki_menu( data, @cmd )
			body =<<-HTML
			<script language="JScript">
			<!--
			 try {
				xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
			} catch (e) {
				xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
			}
			// -->
			</script>
			<script language="JavaScript">
			<!--
			if(typeof XMLHttpRequest != 'undefined'){
				xmlhttp = new XMLHttpRequest();
			}
			function invoke(key) {
				if (!document.getElementById) return;
				if (!xmlhttp) return;
				xmlhttp.open("GET", "#{@conf.cgi_name}#{cmdstr('search', 'key=')}"+encodeURI(key), true);
				xmlhttp.onreadystatechange=function() {
					if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
						document.getElementById("result").innerHTML = xmlhttp.responseText;
					}
				}
				xmlhttp.send(null)
			}
			// -->
			</script>
			<div class="day">
			  <div class="body">
			    <div class="section">
			      <div>#{@conf.msg_search_comment}</div>
			      <form method="GET">
			        #{@conf.msg_search}: <input type="hidden" value="search_orig" name="c">
			        <input size="50" maxlength="50" name="key" onkeyup="invoke(this.value)" onfocus="invoke(this.value)">
			        <input type="submit" value="¸¡º÷">
			      </form>
			      <div id="result">
			      </div>
			    </div>
			  </div>
			</div>
			HTML
			data[:title] = data[:view_title] = title( AjaxSearch::label )
			data[:body] = body.sanitize
			@cmd = 'plugin'
			generate_page(data)
		end

		def search
			if defined?( NKF::UTF8 ) then
				word = NKF::nkf( "-m0 -e", @cgi.params['key'][0] )
			else
				begin
					require 'uconv'
					word = Uconv.u8toeuc( @cgi.params['key'][0] )
				rescue Exception
					word = @cgi.params['key'][0].to_euc
				end
			end
			r = ""
			unless word.empty? then
				total, l = @db.search( word )
				if @conf.hilight_keys
					l.collect! {|p| @plugin.make_anchor("#{@conf.cgi_name}?cmd=view&p=#{p[0].escape}&key=#{word.split.join('+').escape}", @plugin.page_name(p[0])) + " - #{p[1]}"}
				else
					l.collect! {|p| @plugin.hiki_anchor( p[0].escape, @plugin.page_name(p[0])) + " - #{p[1]}"}
				end
				if l.size > 0 then
					r = "<ul>\n" + l.map{|i| "<li>#{i}</li>\n"}.join + "</ul>\n"
				end
			end
			header = Hash::new
			header['type'] = 'text/html'
			header['charset'] = 'EUC-JP'
			header['Content-Language'] = @conf.lang
			header['Pragma'] = 'no-cache'
			header['Cache-Control'] = 'no-cache'
			print @cgi.header( header )
			print r
			nil
		end
	end
end

eval(<<TOPLEVEL_CLASS, TOPLEVEL_BINDING)
module Hiki
	class Command
		def cmd_search_orig
			@conf.template['search_orig'] = @conf.template['search']
			cmd_search
		end
	end
end
TOPLEVEL_CLASS

add_body_enter_proc do
	add_plugin_command( 'search', nil ) 
end
