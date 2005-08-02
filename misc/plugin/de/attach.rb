# $Id: attach.rb,v 1.1 2005-08-02 13:37:41 yanagita Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def attach_files_label
  'Angeh&auml;ngte Dateien'
end

def attach_upload_label
  'Datei hochladen'
end

def detach_upload_label
  'Dateien l&ouml;schen'
end

def plugin_usage_label
	attach_usage
end	

def attach_usage
       '<div><ul>
   <li>Link zu einer angeh&auml;ngten Datei: {{attach_anchor(dateiname [, seitenname])}}.</li>
   <li>Ausgabe einer angeh&auml;ngten Datei: {{attach_view(dateiname [, seitenname])}}.</li>
   <li>Liste aller angeh&auml;ngten Dateien: {{attach_map}}.</li>
   </ul></div>'
end
