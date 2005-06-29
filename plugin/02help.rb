def help_enabled?
  (@conf.style == "default" || @conf.style == "math") && !@conf.mobile_agent?
end

def hiki_help
  @options['help.tlbr_class'] ||= "helptlbr"
  @options['help.bttn_class'] ||= "helpbttn"
  help = <<END_HELP

<script type="text/javascript"><!--

var tlbr_class = "#{@options['help.tlbr_class']}"
var bttn_class = "#{@options['help.bttn_class']}"

var heading_label = "#{help_heading_label}"
var list_label = "#{help_list_label}"
var numbered_label = "#{help_numbered_label}"
var link_label = "#{help_link_label}"
var url_label = "#{help_url_label}"
var emphasized_label = "#{help_emphasized_label}"
var strongly_label = "#{help_strongly_label}"
var struckout_label = "#{help_struckout_label}"
var definition_label = "#{help_definition_label}"
var table_label = "#{help_table_label}"
var cell_label = "#{help_cell_label}"
var headingcell_label = "#{help_headingcell_label}"
var rows_label = "#{help_rows_label}"
var columns_label = "#{help_columns_label}"
var horizontal_label = "#{help_horizontal_label}"
var multiplelines_label = "#{help_multiplelines_label}"
var preformatted_label = "#{help_preformatted_label}"
var cancel_label = "#{help_cancel_label}"
var quotation_label = "#{help_quotation_label}"
var comment_label = "#{help_comment_label}"
var math_label = "#{help_math_label}"
var display_label = "#{help_display_label}"
var inline_label = "#{help_inline_label}"
var plugin_label = "#{help_plugin_label}"
var br_label = "#{help_br_label}"
var toc_label = "#{help_toc_label}"
var tochere_label = "#{help_tochere_label}"
var recent_label = "#{help_recent_label}"

function set_s( pre, suf, mg ){
  txtarea.focus();
  if ( typeof(document["selection"]) != "undefined" ) {
  // for IE, Opera ?
    var rng = document.selection.createRange();
    var str = rng.text
    switch( mg ) {
    case 0:
      rng.text = pre + str + suf;
      break;
    case 1:
      str = str.replace(/\\r/mg, "");
      rng.text = "\\n" + str.replace(/^/mg, pre) + "\\n";
      break;
    case 2:
      var re = new RegExp("^" + pre, "mg");
      rng.text = str.replace( re, "");
      break;
    }
  } else if ( typeof(txtarea["setSelectionRange"]) != "undefined" ) {
  // for Mozilla ?
    var start = txtarea.selectionStart;
    var end = txtarea.selectionEnd;
    var scrollPos = txtarea.scrollTop;
    var str = txtarea.value.substring( start, end );
    var j;
    switch( mg ) {
    case 0:
      j = pre + str + suf;
      break;
    case 1:
      j = "\\n" + str.replace( /^/mg, pre) + "\\n";
      break;
    case 2:
      var re = new RegExp("^" + pre, "mg");
      j = str.replace( re, "");
      break;
    }
    txtarea.value = txtarea.value.substring(0, start) + j + txtarea.value.substring(end);
    if ( str ) {
      txtarea.setSelectionRange( start + j.length, start + j.length);
    } else {
      txtarea.setSelectionRange(start + pre.length, start + pre.length);
    }
    txtarea.scrollTop = scrollPos;
  }
  txtarea.focus();
}

function set_bttn( tlbr, txt, tps, help ) {
  var sp = document.createElement("span");
  sp.className = bttn_class;
  var a = document.createElement("a");
  a.href = help;
  a.title = tps;
  var atxt = document.createTextNode(txt);
  a.appendChild(atxt);
  sp.appendChild(a);
  tlbr.appendChild(sp);
}

function add_bttn( tlbr, txt, tps, pre, suf ) {
  var help = "javascript:set_s( '" + pre + "', '" + suf + "', 0 )";
  set_bttn( tlbr, txt, tps, help );
}

function add_bttn_mg( tlbr, txt, tps, pre, mg ) {
  var help = "javascript:set_s( '" + pre + "', '', " + mg + " )";
  set_bttn( tlbr, txt, tps, help );
}

function add_pbttn( txt, tps, pre, suf ) {
  add_bttn( ptlbr, txt, tps, pre, suf )
}

function add_txt( tlbr, txt ) {
  var tn = document.createTextNode( txt );
  tlbr.appendChild( tn );
}

function add_ptxt( txt ) {
  add_txt( ptlbr, txt )
}
END_HELP

  help << <<'END_HELP'

function set_tlbr() {

  add_txt( tlbr, "[" + heading_label + "|" );
  add_bttn( tlbr, "1", "!TEXT", "\\n!", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, "2", "!!TEXT", "\\n!!", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, "3", "!!!TEXT", "\\n!!!", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, "4", "!!!!TEXT", "\\n!!!!", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, "5", "!!!!!TEXT", "\\n!!!!!", "" );
  add_txt( tlbr, "]" );

  add_txt( tlbr, "[" + list_label + "|" );
  add_bttn( tlbr, "1", "*TEXT", "*", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, "2", "**TEXT", "**", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, "3", "***TEXT", "***", "" );
  add_txt( tlbr, "|" + numbered_label + "|" );
  add_bttn( tlbr, "1", "#TEXT", "#", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, "2", "##TEXT", "##", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, "3", "###TEXT", "###", "" );
  add_txt( tlbr, "]" );

  add_txt( tlbr, "[" );
  add_bttn( tlbr, link_label, "[[TEXT]]", "[[", "]]" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, url_label, "[[TEXT|http://]]", "[[", "|http://]]" );
  add_txt( tlbr, "]" );

  add_txt( tlbr, "[" );
  add_bttn( tlbr, emphasized_label, "\'\'TEXT\'\'", "\\'\\'", "\\'\\'" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, strongly_label, "\'\'\'TEXT\'\'\'", "\\'\\'\\'", "\\'\\'\\'" );
  add_txt( tlbr, "]" );
  
  add_txt( tlbr, "[" );
  add_bttn( tlbr, struckout_label, "==TEXT==", "==", "==" );
  add_txt( tlbr, "]" );

  add_txt( tlbr, "[" );
  add_bttn( tlbr, definition_label, ":WORD:TEXT", "\\n:", ":" );
  add_txt( tlbr, "]" );

  add_txt( tlbr, "[" + table_label + "|" );
  add_bttn( tlbr, cell_label, "||TEXT", "||", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, headingcell_label, "||!TEXT", "!", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, rows_label, "||^TEXT", "^", "" );
  add_txt( tlbr, "|" );
  add_bttn( tlbr, columns_label, "||>TEXT", ">", "" );
  add_txt( tlbr, "]" );

  add_txt( tlbr, "[" );
  add_bttn( tlbr, horizontal_label, "----", "\\n----\\n", "" );
  add_txt( tlbr, "]" );

}

function set_mtlbr() {

  add_txt( mtlbr, "<" + multiplelines_label + ">" );

  add_txt( mtlbr, "[" );
  add_bttn_mg( mtlbr, preformatted_label, " TEXT\\n TEXT", " ", 1 );
  add_txt( mtlbr, "\(" );
  add_bttn_mg( mtlbr, cancel_label, "TEXT\\nTEXT", " ", 2 );
  add_txt( mtlbr, "\)" );
  add_txt( mtlbr, "]" );

  add_txt( mtlbr, "[" );
  add_bttn_mg( mtlbr, quotation_label, "\"\"TEXT\\n\"\"TEXT", "\\\"\\\"", 1 );
  add_txt( mtlbr, "\(" );
  add_bttn_mg( mtlbr, cancel_label, "TEXT\\nTEXT", "\\\"\\\"", 2 );
  add_txt( mtlbr, "\)" );
  add_txt( mtlbr, "]" );

  add_txt( mtlbr, "[" );
  add_bttn_mg( mtlbr, comment_label, "//TEXT\\n//TEXT", "//", 1 );
  add_txt( mtlbr, "\(" );
  add_bttn_mg( mtlbr, cancel_label, "TEXT\\nTEXT", "//", 2 );
  add_txt( mtlbr, "\)" );
  add_txt( mtlbr, "]" );

}

function set_mathtlbr() {
  add_txt( mtlbr, "[" + math_label + "|" );
  add_bttn_mg( mtlbr, display_label, "$$TEXT\\n$$TEXT", "$$$", 1 );
  add_txt( mtlbr, "\(" );
  add_bttn_mg( mtlbr, cancel_label, "TEXT\\nTEXT", "\\\\$\\\\$", 2 );
  add_txt( mtlbr, "\)" );
  add_txt( mtlbr, "|" );
  add_bttn( mtlbr, inline_label, "[$TEXT$]", "[$", "$]" );
  add_txt( mtlbr, "]" );
}

function set_ptlbr() {

  add_ptxt( "[" );
  add_pbttn( plugin_label, "{{TEXT}}", "{{", "}}" );
  add_ptxt( "]" );

  add_ptxt( "[" );
  add_pbttn( br_label, "{{br}}", "{{br}}", "" );
  add_ptxt( "|" );
  add_pbttn( toc_label, "{{toc}}", "\\n{{toc}}\\n", "" );
  add_ptxt( "|" );
  add_pbttn( tochere_label, "{{toc_here}}", "\\n{{toc_here}}\\n", "" );
  add_ptxt( "|" );
  add_pbttn( recent_label, "{{recent\(num\)}}", "\\n{{recent\(20\)}}\\n", "" );
  add_ptxt( "]" );

}

function view_tlbr( tlbr ) {
  tlbr.className = tlbr_class;
  txtarea.parentNode.insertBefore(tlbr, txtarea);
}
END_HELP

  help << <<END_HELP

// main
  var txtarea = document.forms[0].contents;
  var tlbr = document.createElement("div");
  var mtlbr = document.createElement("div");
  var ptlbr = document.createElement("div");

  set_tlbr()
  view_tlbr( tlbr )

  set_mtlbr()
END_HELP

if @conf.style == "math"
  help << <<END_HELP
  set_mathtlbr()
END_HELP
end

  help << <<END_HELP

  view_tlbr( mtlbr )

  set_ptlbr()
  view_tlbr( ptlbr )

// --></script>
END_HELP
  help
end

def help_add_pbttn( help_txt, help_tps, help_pre, help_suf )
  return unless help_enabled?
  add_edit_proc do
    help = <<END_HELP

<script type="text/javascript"><!--

  var txt = "#{help_txt}"
  var tps = "#{help_tps}"
  var pre = "#{help_pre}"
  var suf = "#{help_suf}"

  add_ptxt( "[" );
  add_pbttn( txt, tps, pre, suf );
  add_ptxt( "]" );

// --></script>

END_HELP
    help
  end
end

if help_enabled?
  add_edit_proc do
    hiki_help
  end
end

# export no methods
export_plugin_methods
