# $Id: similarity.rb,v 1.3 2004-03-04 06:15:19 hitoshi Exp $

def similarity(style, permalink)
  s = <<"EOS"
<div class="similarity">
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
