# $Id: cd.rb,v 1.3 2004-03-01 09:50:45 hitoshi Exp $
# Copyright (C) 2003 not <not@cds.ne.jp>
def cd(code)

  amazon_id = @options['amazon.aid'].to_s
  amazon_id = '&amp;tag=' + amazon_id unless amazon_id.empty?

  keyword = code.to_s
  keyword.sub!(/([^\d])(\d+.*)$/, "\\1-\\2") unless keyword.index('-')
  keyword_prefix, keyword_num = keyword.split('-')
  keyword2 = keyword.delete('-').sub(/([^\d])0+(\d+.*)$/, "\\1\\2")
  keyword3 = keyword2.sub(/[A-Za-z]$/, '')
  t = '¡Ú '
  t << make_anchor( 'http://www.amazon.co.jp/exec/obidos/search-handle-url/index=blended%26field-keywords=' + keyword + amazon_id + '/', 'amazon' ) + ' / '
  t << make_anchor( 'http://www.hmv.co.jp/search/title.asp?category=CATALOGUENO&amp;keyword=' + keyword3, 'hmv' ) + ' / '
  t << make_anchor( 'http://www.towerrecords.co.jp/sitemap/CSfSearchResults.jsp?keyword=AllCatalog&amp;SEARCH_GENRE=ALL&amp;entry=' + keyword, 'TOWER' ) + ' / '
  t << make_anchor( 'http://www.netdirect.co.jp/search/ISSSchDetail.asp?ISBN=' + keyword2, '°°²°' ) + ' / '
  t << make_anchor( 'http://www.neowing.co.jp/detailview.html?KEY=' + keyword, 'NeoWing' ) + ' / '
  t << make_anchor( 'http://www.ebisurecords.jp/shop/goods/search.asp?shop=&amp;goods=' + keyword, 'EBISU' ) + ' / '
  t << make_anchor( 'http://search.www.tsutaya.co.jp/search_q/all/index.pl?RBT_SELECT=1&amp;TXT_SEARCH=&amp;TXT_SEARCH1=' + keyword_prefix + '&amp;TXT_SEARCH2=' + keyword_num + '&amp;BTN_SEARCH_2=%8C%9F%8D%F5%82%B7%82%E9', 'TSUTAYA' ) + ' ¡Û'

end

