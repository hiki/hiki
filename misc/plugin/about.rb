# $Id: about.rb,v 1.2 2004-03-01 09:50:45 hitoshi Exp $
# Copyright (C) 2003 OZAWA Sakuro <crouton@users.sourceforge.jp>

def about_not_found_label; 'Documentation not found.'; end

def about(plugin_name, top_wanted=1)
  about_plugin = 'about_' + plugin_name
  text = respond_to?(about_plugin) ? send(about_plugin) : about_not_found_label
  tokens = Parser.new.parse(text)
  HTMLFormatter.new(remap_headings(tokens, top_wanted), @db, self).to_s
end

def about_plugins(top=1)
  abouts = methods.select {|m| /^about_/ =~ m }
  abouts.reject! {|m| m == 'about_plugins' || m == 'about_not_found_label' }
  parser = Parser.new
  result = ''
  abouts.collect do |m|
    heading = m.sub(/^about_/, 'About ')   
    name = m.sub(/^about_/, '')   
    result << HTMLFormatter.new(parser.parse('!' * top + heading + "\n"), @db, self).to_s
    result << about(name, top + 1)
  end
  result
end

def about_about
  <<-EOS
!Syntax
 {{about(PLUGIN_NAME[, TOP_WANTED=1])}}
 {{about_plugins([TOP_WANTED=1])}}
!Description  
This plugin looks for a plugin method about_PLUGIN_NAME.
If it is found, call it and insert the formatted result.

To get all result of about_foobar concatenaed, use about_plugins.

Optional TOP_WANTED argument determines which level the headings
in original text are mapped to in formatted result.
  EOS
end

