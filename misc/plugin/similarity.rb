# $Id: similarity.rb,v 1.2 2004-03-02 03:13:16 hitoshi Exp $

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
