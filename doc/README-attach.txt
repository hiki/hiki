! 使い方
hiki.cgi のあるディレクトリに misc/plugin/attach/attach.cgi を
コピーします。また、
misc/plugin ディレクトリに misc/plugin/attach/attach.rb を
コピーするか、symlink を張ります。
その後、「管理」->「プラグイン選択」で attach.rb を有効にして下さい。

!! HikiFarm 時
上記の手順に加えて、次のいずれかの方法で使います。

!!! (A) ファイルを作る
  $ cat attach.cgi
  #!/usr/bin/env ruby
  hiki=''
  eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
  $:.unshift "#{hiki}"
  load "#{hiki}/misc/plugin/attach.cgi"

のような attach.cgi を、各 Hiki のある CGI のディレクトリに置いてください。

!!! (B) symlink を作る
hiki.cgi にコピーした attach.cgi 宛の symlink を置いてください。
(直接 misc/plugin/attach/attach.cgi 宛に symlink をはったら、ライブラリ
がロードできないので動作しません)
