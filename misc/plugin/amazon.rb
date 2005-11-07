# amazon.rb $Revision: 1.9 $
#
# isbn_image_left: 指定したISBNの書影をclass="left"で表示
#   パラメタ:
#     asin:    ASINまたはISBN(必須)
#     comment: コメント(省略可)
#
# isbn_image_right: 指定したISBNの書影をclass="right"で表示
#   パラメタ:
#     asin:    ASINまたはISBN(必須)
#     comment: コメント(省略可)
#
# isbn_image: 指定したISBNの書影をclass="amazon"で表示
#     asin:    ASINまたはISBN(必須)
#     comment: コメント(省略可)
#
# isbn: amazonにアクセスしない簡易バージョン。
#     asin:    ASINまたはISBN(必須)
#     comment: コメント(必須)
#
#   ASINとはアマゾン独自の商品管理IDです。
#   書籍のISBNをASINに入力すると書籍が表示されます。
#
#   それぞれ商品画像が見つからなかった場合は
#       <a href="amazonのページ">商品名</a>
#   のように商品名を表示します。
#   コメントが記述されている場合は商品名がコメントの内容に変わります。
#
# tdiary.confにおける設定:
#   @options['amazon.aid']:   アソシエイトIDを指定することで、自分のア
#                             ソシエイトプログラムを利用できます
#   @options['amazon.proxy']: 「host:post」形式でHTTP proxyを指定すると
#                             Proxy経由でAmazonの情報を取得します
#
#
# 注意：著作権が関連する為、www.amazon.co.jpのアソシエイトプログラムを
# 確認の上利用して下さい。
#
# Copyright (C) 2002 by HAL99 <hal99@mtj.biglobe.ne.jp>
#
# Original: HAL99 <hal99@mtj.biglobe.ne.jp>
# Modified: by TADA Tadashi<sho@spc.gr.jp>,
#              kazuhiko<kazuhiko@fdiary.net>,
#              woods<sodium@da2.so-net.ne.jp>,
#              munemasa<munemasa@t3.rim.or.jp>,
#              dai<dai@kato-agri.com>
#
=begin ChangeLog
2003-03-04 TADA Tadashi
        * follow to changing book title style in Amazon's HTML.

2003-02-09 Junichiro Kita <kita@kitaj.no-ip.com>
        * merge from amazon2.rb. see http://kuwa.s26.xrea.com/b/20030211.html

2003-01-13 TADA Tadashi <sho@spc.gr.jp>
        * for ruby 1.6.8. thanks woods <sodium@da2.so-net.ne.jp>.

2002-11-28 TADA Tadashi <sho@spc.gr.jp>
        * HTML 4.01 Strict support.

2002-09-01 Junichiro Kita <kita@kitaj.no-ip.com>
        * change URL for images.

2002-07-09 TADA Tadashi <sho@spc.gr.jp>
        * follow chaging of title format in amazon.
=end

require 'net/http'
require 'timeout'

def getAmazon( asin )

        cache = "#{@cache_path}/amazon"

        Dir::mkdir( cache ) unless File::directory?( cache )
        begin
                item = File::readlines( "#{cache}/#{asin}".untaint )
                raise if item.length < 2

                return item
        rescue
        end

        limittime = 10

        proxy_host = nil
        proxy_port = 8080
        if /^([^:]+):(\d+)$/ =~ @options['amazon.proxy'] then
                proxy_host = $1
                proxy_port = $2.to_i
        end

        item_url = nil
        item_name = asin
        img_url = nil
        img_name = nil
        img_height = nil
        img_width = nil

        timeout( limittime ) do
                item_url = "http://www.amazon.co.jp/exec/obidos/ASIN/#{asin}"

                begin
                        if %r|http://([^:/]*):?(\d*)(/.*)| =~ item_url then
                                host = $1
                                port = $2.to_i
                                path = $3
                                raise 'not amazon domain' if host !~ /\.amazon\.(com|co\.uk|co\.jp|de|fr)$/
                                raise 'bad location was returned.' unless host and path
                                port = 80 if port == 0
                        end
                        Net::HTTP.version_1_1
                        Net::HTTP.Proxy( proxy_host.untaint, proxy_port.untaint ).start( host.untaint, port.untaint ) do |http|
                                response, = http.get( path )
                                response.body.each do |line|
                                        line = NKF::nkf( "-e", line )
                                        if line =~ %r|^Amazon.co.jp[:：](.*?)(\s*</title>)?$|
                                                item_name = CGI::escapeHTML(CGI::unescapeHTML($1))
                                        end
                                        if line =~ /(<img src="(http\:\/\/images-jp\.amazon\.com\/images\/P\/(.*[ML]ZZZZZZZ_?.jpg))".*?>)/i
                                                img_tag = $1
                                                img_url = $2
                                                img_name = $3
                                                if img_tag =~ / width="?(\d+)"?/i
                                                        img_width = $1
                                                end
                                                if img_tag =~ / height="?(\d+)"?/i
                                                        img_height = $1
                                                end
                                        end
                                end
                        end
                rescue Net::ProtoRetriableError => err
                        item_url = err.response['location']
                        retry
                rescue
                        raise 'getting item was failed'
                end
        end
        item = [item_url.strip,item_name,img_url,img_name,img_width,img_height]
        open("#{cache}/#{asin}".untaint,"w") do |f|
                item.each do |i|
                        next unless i
                        f.print i,"\n"
                        end
        end
        return item
end

def amazonNoImg(item_url,item_name)
        %Q[<a href="#{item_url.strip}/ref=nosim/">#{item_name.strip}</a>]
end


def getAmazonImg(position,asin,comment)
        begin
                item = getAmazon(asin)
                item[0].sub!( %r|[^/]+$|, @options['amazon.aid'] ) if @options['amazon.aid']

                item_name = item[1]
                item[1] = comment if comment
                unless item[2]
                        return amazonNoImg(item[0],item[1])
                end
                r = ""
                r << %Q[<a href="#{item[0].strip}/ref=nosim/">]
                r << %Q[<img class="#{position}" src="#{item[2].strip}" ]
                r << %Q[width="#{item[4].strip}" ] if item[4]
                r << %Q[height="#{item[5].strip}" ] if item[5]
                r << %Q[alt="#{item[1].strip}">]
                r << item[1].strip if position == "amazon"
                r << %Q[</a>]
        rescue
                asin
        end
end

def isbnImgLeft(asin,comment = nil)
        getAmazonImg("left",asin,comment)
end
alias isbn_image_left isbnImgLeft

def isbnImgRight(asin,comment = nil)
        getAmazonImg("right",asin,comment)
end
alias isbn_image_right isbnImgRight

def isbnImg(asin,comment = nil)
        return "invalid asin: '#{asin}'" unless /\A[a-zA-Z\d]+\Z/ =~ asin
        getAmazonImg("amazon",asin,comment)
end
alias isbn_image isbnImg
alias amazon isbnImg

def isbn( asin, comment )
        item_url = "http://www.amazon.co.jp/exec/obidos/ASIN/#{asin}/"
        item_url << @options['amazon.aid'] if @options['amazon.aid']
        amazonNoImg( item_url, comment )
end
