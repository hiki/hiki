# $Id: similarity.rb,v 1.1 2004-03-02 02:46:41 hitoshi Exp $
# Copyright (C) 2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def similarity(style, permalink)
  s = <<"EOS"
<div class="similariry">
<script language="JavaScript">
var url = '#{permalink}';
var n = 10;
var oe = 'euc-jp';
var style = '#{style}'
document.write('<scr' + 'ipt language="JavaScript" src="http://bulkfeeds.net/app/similar.js?url=' + escape(url) 
+ '&amp;n=' + n + '&amp;style=' + style 
+ '&amp;oe=' + oe + '"></scr' + 'ipt>');
</script>
</div>
EOS
end
