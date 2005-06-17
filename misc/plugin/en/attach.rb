# $Id: attach.rb,v 1.4 2005-06-17 05:03:43 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def attach_files_label
  'Attached Files'
end

def attach_upload_label
  'File Upload'
end

def detach_upload_label
  'Remove files'
end

def attach_usage
       '<div><ul>
   <li>Anchor to the attached file is {{attach_anchor(file name [, page name])}}.</li>
   <li>Indication of the attached file is {{attach_view(file name [, page name])}}.</li>
   <li>List of the attached pages and files is {{attach_map}}.</li>
   </ul></div>'
end
