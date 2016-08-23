# English resources of 01sp.rb $Revision: 1.1 $

=begin
= Select-plugin plugin

== Abstract
Selects which plugin to be actually used.

== Usage
Put this file into the plugin/ directory.

Next, move the plugins you want to be optional into another directory.
In the example below, these plugins are assumed to be in
plugin/selectable directory.

Finally, edit the tdiary.conf file in the same directory as tdiary.rb
and add the following line:
  @options['sp.path'] = 'misc/plugin'
to indicate the directory you have put the optional plugins. It can be
an absolute path.

You can use this plugin in a secure diary.

== Options
:@options['sp.path']
        Directory name where the optional plugins are, relative from the
  directory where tdiary.rb is or absolute.

:@options['sp.usenew']
  Define true if you want to the users to try a newly installed plugin.
        Newly installed plugins are detected next time when the user configures
        this plugin.

== Copyright notice
Copyright (C) 2003 zunda <zunda at freeshell.org>

Permission is granted for use, copying, modification, distribution, and
distribution of modified versions of this work under the terms of GPL
version 2 or later.
=end

@sp_label = "Plugin Auswahl"
@sp_label_description = "<p>W&auml;hlt das gew&uuml;nschte Plugin.</p>"
@sp_label_please_select = "<p>Bitte die gew&uuml;nschten Plugins hier ausw&auml;hlen. Jeder Plugin-Dateiname ist mit einer eigenen Hilfeseite verbunden. Bitte erstelle oder verbessere die Hilfeseite!</p>"
@sp_label_new = "<h4>Neu! Probiers aus.</h4>"
@sp_label_used = "<h4>In benutzung</h4>"
@sp_label_notused = "<h4>Derzeit nicht benutzt</h4>"
@sp_label_noplugin = "<p>Es gibt keine optionalen Plugins.</p>"
