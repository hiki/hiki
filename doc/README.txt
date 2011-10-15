◆ Hikiとは ◆

HikiはいわゆるひとつのWikiエンジンです。Hikiには以下の特徴があります。


○ オリジナルWikiに似たシンプルな書式

HikiはオリジナルのWikiに似たシンプルな書式をサポートしています。詳細につ
いては http://hikiwiki.org/ja/TextFormattingRules.html を参照してください。


○ CSSを使ったテーマ機能

スタイルシートを使って簡単に見た目を変えることができ、これはテーマと呼ば
れます。Hikiでは、ただただしさん作の日記システムtDiary用の豊富なテーマを
使用することができます。


○ プラグインによる機能拡張

プラグインにより機能を追加することができます。tDiaryの（日記に依存しない）
プラグイン資産を最大限生かせる方向で実装を進めています。


○ HikiFarmに対応

HikiFarmを一つ設置すれば、ブラウザ上から簡単に新しいHikiをいくつも作るこ
とができます。詳しくは misc/hikifarm/README をご覧ください。


○ 出力するHTMLを柔軟に変更可能

Hikiでは文書埋め込みRubyスクリプトERBを使っているため、
出力するHTMLの形式を柔軟に変更することができます。


○ InterWikiのサポート

InterWikiをサポートしています。InterWikiとは、もともとはWikiサーバー間を
つなげる機能だった（らしい）のですが、使い方によってはWikiサーバー以外へ
のリンクすることができます。たとえばInterWikiNameというページに以下のよう
に書いた後、

 *[[ruby-list|http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/]]
 *[[Hiki|http://hikiwiki.org/ja/?]] euc

任意のページに、
 [[Hiki:HikiFarm]]

と書くとhttp://hikiwiki.org/ja/の「HikiFarm」という
ページへのリンクになります。

同様に、
 [[ruby-list:1]]

と書くとruby-listメーリングリストの1番のメールへのリンクになります。


○ ページにカテゴリ付けできる

標準で提供されるプラグイン(category.rbまたはkeyword.rb)により各ページに
カテゴリを付けて、カテゴリ単位でページを扱うことができます。



◆ 著作権、サポートなど ◆

Hikiは、GNU GPL2 で配布、改変を許可するフリーソフトウェアです。Hikiの原作
者は「たけうちひとし」で、現在ではHiki開発チームにより開発されています。

ただし、配布ファイルのうち以下のものはそれぞれの原作者が著作権を有します。

hiki/db/tmarshal.rb
  るびきちさんがruby-list:30305にポストしたスクリプトを若干修正したもの。Ruby ライセンスで配布。 
hiki/docdiff/*
  森田尚さん作。修正BSDライセンスで配布。
hiki/image_size.rb
  Keisuke Minami さん作。Ruby ライセンスで配布

Hiki は http://hikiwiki.org/ja/ でサポートを行っています。
ご意見・ご要望はこちらへどうぞ。
