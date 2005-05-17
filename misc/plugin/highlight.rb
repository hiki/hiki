# highlight.rb $Revision: 1.3 $
#
# ジャンプ先のエレメントをハイライトする。通称「謎JavaScript。最終形態」
# インストールするだけで動作します。
#
# オプション:
#                        @options["highlight.color"]:      ハイライトの文字色(省略時:白)
#                        @options["highlight.background"]: ハイライトの背景色(省略時:赤)
#
# See: http://tdiary-users.sourceforge.jp/cgi-bin/wiki.cgi?%A5%EA%A5%F3%A5%AF%B8%B5%A4%F2%A4%BF%A4%C9%A4%C3%A4%C6%A4%E2%A1%A2%A4%C9%A4%B3%A4%CE%CF%C3%C2%EA%A4%AB%A4%EF%A4%AB%A4%E9%A4%CA%A4%A4%A4%F3%A4%C7%A4%B9%A4%B1%A4%C9
#
#2004-02-14 TAKEUCHI Hitoshi
#        * modified for Hiki

add_footer_proc do
        @options['highlight.color'] ||= '#fff'
        @options['highlight.background'] ||= '#f00'

        <<-SCRIPT
                <script type="text/javascript"><!--
                var highlightStyle = new Object();
                highlightStyle.color = "#{CGI::escapeHTML(@options['highlight.color'])}";
                highlightStyle.backgroundColor = "#{CGI::escapeHTML(@options['highlight.background'])}";
                
                var highlightElem = null;
                var saveStyle = null;
                
                function highlightElement(name) {
                        if (highlightElem) {
                                for (var key in saveStyle) {
                                        highlightElem.style[key] = saveStyle[key];
                                }
                                highlightElem = null;
                        }
                
                        highlightElem = getHighlightElement(name);
                        if (!highlightElem) return;
                
                        saveStyle = new Object();
                        for (var key in highlightStyle) {
                                saveStyle[key] = highlightElem.style[key];
                                highlightElem.style[key] = highlightStyle[key];
                        }
                }
                
                function getHighlightElement(name) {
                        for (var i=0; i<document.anchors.length; ++i) {
                                var anchor = document.anchors[i];
                                if (anchor.name == name) {
                                        var elem;
                                        if (anchor.parentElement) {
                                                elem = anchor.parentElement;
                                        } else if (anchor.parentNode) {
                                                elem = anchor.parentNode;
                                        }
                                        return elem;
                                }
                        }
                        return null;
                }
                
                if (document.location.hash) {
                        highlightElement(document.location.hash.substr(1));
                }
                
                hereURL = document.location.href.split(/\#/)[0];
                for (var i=0; i<document.links.length; ++i) {
                        if (hereURL == document.links[i].href.split(/\#/)[0]) {
                                document.links[i].onclick = handleLinkClick;
                        }
                }
                
                function handleLinkClick() {
                        highlightElement(this.hash.substr(1));
                }
                // --></script>
        SCRIPT
end

# vim: ts=3
