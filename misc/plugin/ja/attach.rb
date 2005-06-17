# $Id: attach.rb,v 1.2 2005-06-17 05:03:43 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def attach_files_label
  '添付ファイル'
end

def attach_upload_label
  'ファイルの添付'
end

def detach_upload_label
  'チェックしたファイルを削除'
end

def attach_usage
       '<div><ul>
   <li>添付ファイルへのアンカは、{{attach_anchor(ファイル名 [, ページ名])}}</li>
   <li>添付したファイルの表示は、{{attach_view(ファイル名 [, ページ名])}}</li>
   <li>添付ページとファイルの一覧は、{{attach_map}}</li>
   </ul></div>'
end
