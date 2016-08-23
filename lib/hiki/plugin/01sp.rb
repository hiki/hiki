# 01sp.rb - select-plugins plugin $Revision: 1.6 $

=begin ChangeLog
See ../ChangeLog for changes after this.

* Thu Aug 28, 2003 zunda <zunda at freeshell.org>
- 1.3
- simpler configuration display

* Tue Aug 26, 2003 zunda <zunda at freeshell.org>
- 1.2
- option defaults are flipped
- Typo for @options are fixed

* Tue Aug 26, 2003 zunda <zunda at freeshell.org>
- 1.1
- English translation

* Fri Aug 22, 2003 zunda <zunda at freeshell.org>
- 1.1.2.6
- bug fix: check conf mode before updating the options

* Fri Aug 22, 2003 zunda <zunda at freeshell.org>
- 1.1.2.5
- following options are added: thanks to kaz
- @options['select_plugins.hidesource']
- @options['select_plugins.hidemandatory']
- @options['select_plugins.newdefault']
- new plugins are marked in the list until the user configures the selections

* Wed Aug 20, 2003 zunda <zunda at freeshell.org>
- 1.1.2.1
- first release
=end ChangeLog

SP_PREFIX = "sp"
*@sp_path = *(@conf["#{SP_PREFIX}.path"] || "#{PATH}/../../misc/plugin")
@sp_path = @sp_path.collect do |path|
  /\/$/ =~ path ? path.chop : path
end

# get plugin option
def sp_option(key)
  @conf["#{SP_PREFIX}.#{key}"]
end

# hash of paths from array of dirs
def sp_hash_from_dirs(dirs)
  r = {}
  dirs.each do |dir|
    Dir.glob("#{dir}/*.rb").each do |path|
      filename = File.basename(path)
      r[filename] ||= path
    end
  end
  r
end

# url of the document
def sp_doc_url(file)
  case @conf.lang
  when "ja"
    "http://hikiwiki.org/ja/#{escape(file)}.html"
  else
    "http://hikiwiki.org/en/#{escape(file)}.html"
  end
end

def collect_plugins(sp_opt)
  # categorize the available plugins
  used = []
  notused = []
  unknown = []
  # File.basenmame needed to read option from 01sp.rb <= 1.10
  selected_array = sp_option("selected") ? sp_option("selected").split(/\n/).collect{ |p| File.basename(p) } : []
  notselected_array = sp_option("notselected") ? sp_option("notselected").split(/\n/).collect{ |p| File.basename(p) } : []
  sp_opt.keys.each do |path|
    if selected_array.include?(path) then
      used << path
    elsif notselected_array.include?(path) then
      notused << path
    else
      unknown << path
    end
  end
  [used, notused, unknown]
end

# <li> list of plugins
def sp_li_plugins(paths, with_checkbox, is_checked)
  paths.collect { |path| File.basename(path) }.sort.inject("") do |result, file|
    checkbox = with_checkbox ? %Q!<input name="#{SP_PREFIX}.#{h(file)}" type="checkbox" value="t"#{is_checked ? ' checked' : ''}>! : ""
    result << %Q!<li>#{checkbox}<a href="#{sp_doc_url(file)}">#{h(file)}</a>!
  end
end

# lists of plugins
def sp_list_plugins(sp_opt, with_checkbox)
  r = ""
  if sp_opt.empty?
    return @sp_label_noplugin
  else
    used, notused, unknown = collect_plugins(sp_opt)

    # list up
    r << @sp_label_please_select
    unless unknown.empty? then
      r << @sp_label_new
      r << "<ul>\n"
      r << sp_li_plugins(unknown, with_checkbox, sp_option("usenew"))
      r << "</ul>\n"
    end

    # selected plugins
    unless used.empty? then
      r << @sp_label_used
      r << "<ul>\n"
      r << sp_li_plugins(used, with_checkbox, true)
      r << "</ul>\n"
    end

    # not selected plugins
    unless notused.empty? then
      r << @sp_label_notused
      r << "<ul>\n"
      r << sp_li_plugins(notused, with_checkbox, false)
      r << "</ul>\n"
    end
  end
  r
end

# things needed to configure this plugin
if SP_PREFIX == @request.params["conf"]
  # list of plugins
  @sp_opt = sp_hash_from_dirs(@sp_path)

  # update options
  # we have to do this when we are eval'ed to update the config menu
  if /saveconf/ =~ @mode
    @conf["#{SP_PREFIX}.selected"] = ""
    @conf["#{SP_PREFIX}.notselected"] = ""
    @sp_opt.each_key do |file|
      if "t" == @request.params["#{SP_PREFIX}.#{file}"]
        @conf["#{SP_PREFIX}.selected"] << "#{file}\n"
      else
        @conf["#{SP_PREFIX}.notselected"] << "#{file}\n"
      end
    end
  end
end

# configuration menu
# options are updated when we are eval'ed
add_conf_proc(SP_PREFIX, @sp_label) do
  r = ""
  r << @sp_label_description
  r << sp_list_plugins(@sp_opt, true)
end

# Finally, we can eval the selected plugins as tdiary.rb does
if sp_option("selected")
  sp_option("selected").untaint.split(/\n/).collect{ |p| File.basename(p) }.sort.each do |filename|
    @sp_path.each do |dir|
      path = "#{dir}/#{filename}"
      if File.readable?(path)
        begin
          load_plugin(path)
          @plugin_files << path
        rescue Exception
          raise PluginError.new("Plugin error in '#{path}'.\n#{$!}")
        end
        break
      end
    end
  end
end

# The `show_plugins' plugin is enabled in show_plugins.rb
def show_plugins
  used = @conf["#{SP_PREFIX}.selected"].split(/\n/).collect{ |p| File.basename(p) }.sort
  used.empty? ? "" : "<ul>\n" + sp_li_plugins(used, false, true) + "</ul>\n"
end

export_plugin_methods()

