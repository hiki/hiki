{{toc}}

!Hikiとは
HikiはいわゆるひとつのWikiエンジンです。Hikiには以下の特徴があります。

!!オリジナルWikiに似たシンプルな書式
HikiはオリジナルのWikiに似たシンプルな書式をサポートしています。詳細については[[Hiki:TextFormattingRules]]を参照してください。

!!CSSを使ったテーマ機能
スタイルシートを使って簡単に見た目を変えることができ、これはテーマと呼ばれます。
Hikiでは、ただただしさん作の日記システム[[tDiary|http://www.tdiary.org/]]用の
[[豊富なテーマ|http://www.tdiary.net/theme.rhtml]]を使用することができます。

!!プラグインによる機能拡張
プラグインにより機能を追加することができます。プラグインについては、現段階では
仕様が流動的なのですが、tDiaryの（日記に依存しない）プラグイン資産を最大限
生かせる方向で検討中です。

!!出力するHTMLを柔軟に変更可能
HikiではRuby用のHTML/XMLテンプレートライブラリ
[[Amrita|http://www.brain-tokyo.jp/research/amrita/index_ja.html]]を
使っているため、出力するHTMLの形式を柔軟に変更することができます。

!!InterWikiのサポート
InterWikiをサポートしています。InterWikiとは、もともとはWikiサーバー間を
つなげる機能だった（らしい）のですが、使い方によってはWikiサーバー以外への
リンクすることができます。たとえばInterWikiNameというページに以下のように書いた後、

 *[[ruby-list|http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/]]
 *[[Hiki|http://www.namaraii.com/hiki/hiki.cgi?]] euc

任意のページに、
 [[Hiki:逆引きRuby]]

と書くとhttp://www.namaraii.com/hiki/hiki.cgiの「逆引きRuby」という
ページへのリンクになります。

同様に、
 [[ruby-list:1]]

と書くとruby-listメーリングリストの1番のメールへのリンクになります。

!!ページにカテゴリ付けできる
標準で提供されるプラグインにより各ページにカテゴリを付けて、カテゴリ単位
でページを扱うことができます。（現状はカテゴリ単位のページ一覧のみ）

!!Rubyで記述されている
Rubyで記述されていることと、Rubyらしいプログラムであることは別です。
Hikiの場合Rubyで記述されたRubyらしくないプログラムです。
もちろん、わざとそうしているわけではないのが悲しいところですが、
少しずつRubyらしいプログラムにしていけたらなぁと考えています。

…ということで、皆様のコメントをお待ちしております。

!著作権、サポートなど
Hikiは作者である竹内 仁(hitoshi@namaraii.com)がGPL2で配布、改変を
許可するフリーソフトウェアです。無保証です。

ただし、配布ファイルのうち以下のものは竹内が開発したものではなく、
それぞれの原作者が著作権を有します。

:hiki/algorithm/diff.rb:Lars Christensen氏作。GPL2で配布。 
:hiki/db/tmarshal.rb:るびきちさんがruby-list:30305にポストしたスクリプトを若干修正したもの。Ruby'sで配布。 

Hikiはhttp://www.namaraii.com/hiki/でサポートを行っています。ご意見・ご要望はこちらへどうぞ。
