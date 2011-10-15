! 使い方
hiki.cgi のあるディレクトリに misc/plugin/attach/attach.cgi を
コピーします。
その後、「管理」->「プラグイン選択」で attach.rb を有効にして下さい。

!! HikiFarm 時
hikifarm.conf の attach_cgi_name にファイル添付 CGI のファイル名を
指定してください。新しい Hiki を作成すると、その Hiki のディレクトリに
指定したファイル名でファイル添付 CGI が自動生成されます。

  # Hikiのファイル添付用CGIファイル名
  # nil のときは、ファイル添付用CGIは作成しない。
  attach_cgi_name = nil
