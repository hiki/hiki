# $Id: isbn.rb,v 1.3 2005-06-27 13:42:37 fdiary Exp $
# converts from sns isbn.pl
# Copyright (C) 2003 NAKAMURA Noritsugu <nnakamur@mxq.mesh.ne.jp>
# add Amazon Associate ID by Kazuhiko <kazuhiko@fdiary.net>

def isbn(isbn, bookname = "")
  isbn1 = isbn.to_s.gsub(/ISBN/i, "")
  isbn2 = isbn1.gsub(/-/, "")

  if bookname == ""
    buf = ""
  else
    buf = "#{bookname.escapeHTML}"
  end

  aid = @options['amazon.aid'] ? "/#{@options['amazon.aid']}" : ""

  s  = ""
  s << buf
  s << "¡Ú "
  s << make_anchor( "http://www.amazon.co.jp/exec/obidos/ASIN/#{isbn2}#{aid}/ref=nosim/", 'amazon' ) + ' / '
  s << make_anchor( "http://www.bk1.co.jp/search/search.asp?srch=2&amp;kywd=&amp;ti=&amp;au=&amp;pb=&amp;isbn=#{isbn1}&amp;idx=1", 'bk1' ) + ' / '
  s << make_anchor( "http://www.netdirect.co.jp/search/ISSSchDetail.asp?ISBN=#{isbn2}", '°°²°' ) + ' / '
  s << make_anchor( "http://www.jbook.co.jp/product.asp?isbn=#{isbn2}", 'Jbook' ) + ' / '
  s << make_anchor( "http://bookweb.kinokuniya.co.jp/guest/cgi-bin/wshosea.cgi?W-ISBN=#{isbn2}", 'µª°ËÔ¢²°' ) + ' / '
  s << make_anchor( "http://www.esbooks.co.jp/bks.svl?CID=BKS504&amp;access_method=isbn_cd&amp;input_data=#{isbn1}", 'eS!' ) + ' / '
  s << make_anchor( "http://bsearch.rakuten.co.jp/Btitles?KEY=#{isbn1}", '³ÚÅ·' )
  s << " ¡Û"
end
