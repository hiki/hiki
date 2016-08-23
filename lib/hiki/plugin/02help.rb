def help_enabled?
  (@conf.style == "default" || @conf.style == "math") && !@conf.mobile_agent?
end

def hiki_help
  @options["help.tlbr_class"] ||= "helptlbr"
  @options["help.bttn_class"] ||= "helpbttn"
  help = <<END_HELP

<script type="text/javascript"><!--

var tlbr_class = "#{@options['help.tlbr_class']}";
var bttn_class = "#{@options['help.bttn_class']}";

var lineshelp_label = "#{help_lineshelp_label}";
var wordshelp_label = "#{help_wordshelp_label}";
var tablehelp_label = "#{help_tablehelp_label}";
var pluginhelp_label = "#{help_pluginhelp_label}";
var mathhelp_label = "#{help_mathhelp_label}";

var heading_label = "#{help_heading_label}";
var list_label = "#{help_list_label}";
var numbered_label = "#{help_numbered_label}";
var preformatted_label = "#{help_preformatted_label}";
var quotation_label = "#{help_quotation_label}";
var comment_label = "#{help_comment_label}";
var cancel_label = "#{help_cancel_label}";

var link_label = "#{help_link_label}";
var url_label = "#{help_url_label}";
var emphasized_label = "#{help_emphasized_label}";
var strongly_label = "#{help_strongly_label}";
var struckout_label = "#{help_struckout_label}";
var definition_label = "#{help_definition_label}";
var horizontal_label = "#{help_horizontal_label}";

var cell_label = "#{help_cell_label}";
var headingcell_label = "#{help_headingcell_label}";
var rows_label = "#{help_rows_label}";
var columns_label = "#{help_columns_label}";

var plugin_label = "#{help_plugin_label}";
var br_label = "#{help_br_label}";
var toc_label = "#{help_toc_label}";
var tochere_label = "#{help_tochere_label}";
var recent_label = "#{help_recent_label}";

var display_label = "#{help_display_label}";
var inline_label = "#{help_inline_label}";

function showhelp( id ) {
  if ( document.getSelection ) {
  // for SelectionKeep on FireFox ?
    txtarea.focus();
    var start = txtarea.selectionStart;
    var end = txtarea.selectionEnd;
    var scrollPos = txtarea.scrollTop;
    txtarea.setSelectionRange( start, end );
    txtarea.scrollTop = scrollPos;
  } else if ( window.getSelection ) {
  // for Safari ?
    txtarea.focus();
  }
  for ( i=0; i < tlbr_ids.length; i++ ){
    if ( tlbr_ids[i] == id ) {
      document.getElementById( tlbr_ids[i] ).style.display = "";
    } else {
      document.getElementById( tlbr_ids[i] ).style.display = "none";
    }
  }
}

function set_s( pre, suf, mg ){
  txtarea.focus();
  if ( document.getSelection || window.getSelection) {
  // for Mozilla, Opera, Safari ?
    var start = txtarea.selectionStart;
    var end = txtarea.selectionEnd;
    var scrollPos = txtarea.scrollTop;
    var str = txtarea.value.substring( start, end );
    var str0 = txtarea.value.substring( 0, start );
    var str1 = txtarea.value.substring( end );
    var j = "";
    switch( mg ) {
    case 0:
      j = pre + str + suf;
      break;
    case 1:
      str = str.replace(/(\\r\\n|\\r|\\n)$/, "");
      str = str.replace(/\\r\\n|\\r|\\n/mg, "\\n");
      var s = str.split("\\n");
      var i;
      for ( i = 0; i < s.length ; i++ ) {
        j = j + pre + s[i] + "\\n";
      }
      break;
    case 2:
      var re = new RegExp("^" + pre, "mg");
      j = str.replace( re, "");
      break;
    }
    txtarea.value = str0 + j;
    var l = txtarea.value.length;
    txtarea.value = txtarea.value + str1;
    if ( mg > 0 ) {
      txtarea.setSelectionRange( start, l );
    } else if ( str.length > 0 ) {
      txtarea.setSelectionRange( l, l );
    } else {
      l = l - suf.length;
      txtarea.setSelectionRange( l, l );
    }
    txtarea.scrollTop = scrollPos;
  } else if ( document.selection ) {
  // for MSIE ?
    var rng = document.selection.createRange();
    var str = rng.text;
    var j = "";
    switch( mg ) {
    case 0:
      j = pre + str + suf;
      rng.text = j;
      break;
    case 1:
      str = str.replace( /(\\r\\n|\\r|\\n)$/, "");
      str = str.replace( /\\r\\n|\\r/mg, "\\n" );
      var s = str.split( "\\n" );
      var i;
      for ( i = 0; i < s.length ; i++ ) {
        j = j + pre + s[i] + "\\n";
      }
      rng.text = j;
      break;
    case 2:
      str = str.replace( /(\\r\\n|\\r|\\n)$/, "");
      str = str.replace( /\\r\\n|\\n/mg, "\\n" );
      var s = str.split( "\\n" );
      var i;
      var re;
      for ( i = 0; i < s.length ; i++ ) {
        re = new RegExp( "^" + pre );
        j = j + s[i].replace( re, "" ) + "\\n";
      }
      rng.text = j;
      break;
    }
    if ( mg > 0 ) {
      rng.move( "character", -j.length );
      rng.moveEnd( "character", j.length );
      rng.select();
    } else if ( str.length > 0 ) {
      rng.move( "character", 0 );
      rng.select();
    } else {
      rng.move( "character", -suf.length );
      rng.select();
    }
  }
  txtarea.focus();
}

function set_showbttn( txt, id ) {
  var tn = document.createTextNode( "<" );
  stlbr.appendChild( tn );
  var sp = document.createElement( "span" );
  sp.className = bttn_class;
  var a = document.createElement( "a" );
  a.href = "javascript:showhelp( '" + id + "' )";
  var atxt = document.createTextNode( txt );
  a.appendChild( atxt );
  sp.appendChild( a );
  stlbr.appendChild( sp );
  tn = document.createTextNode( ">" );
  stlbr.appendChild( tn );
}

function set_bttn( tlbr, txt, tps, help ) {
  var sp = document.createElement( "span" );
  sp.className = bttn_class;
  var a = document.createElement( "a" );
  a.href = help;
  a.title = tps;
  var atxt = document.createTextNode( txt );
  a.appendChild( atxt );
  sp.appendChild( a );
  tlbr.appendChild( sp );
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
  add_bttn( ptlbr, txt, tps, pre, suf );
}

function add_txt( tlbr, txt ) {
  var tn = document.createTextNode( txt );
  tlbr.appendChild( tn );
}

function add_ptxt( txt ) {
  add_txt( ptlbr, txt );
}

END_HELP

  help << <<'END_HELP'

function set_stlbr() {

  set_showbttn( lineshelp_label, "lines_help" );
  set_showbttn( wordshelp_label, "words_help" );
  set_showbttn( tablehelp_label, "table_help" );
  set_showbttn( pluginhelp_label, "plugin_help" );

}

function set_ltlbr() {

  add_txt( ltlbr, "[" );
  add_bttn_mg( ltlbr, heading_label, "!TEXT\\n!TEXT", "!", 1 );
  add_txt( ltlbr, "\(" );
  add_bttn_mg( ltlbr, cancel_label, "TEXT\\nTEXT", "!", 2 );
  add_txt( ltlbr, "\)][" );
  add_bttn_mg( ltlbr, list_label, "*TEXT\\n\*TEXT", "\*", 1 );
  add_txt( ltlbr, "\(" );
  add_bttn_mg( ltlbr, cancel_label, "TEXT\\nTEXT", "\\\\\*", 2 );
  add_txt( ltlbr, "\)|" );
  add_bttn_mg( ltlbr, numbered_label, "#TEXT\\n#TEXT", "#", 1 );
  add_txt( ltlbr, "\(" );
  add_bttn_mg( ltlbr, cancel_label, "TEXT\\nTEXT", "#", 2 );
  add_txt( ltlbr, "\)][" );
  add_bttn_mg( ltlbr, preformatted_label, " TEXT\\n TEXT", " ", 1 );
  add_txt( ltlbr, "\(" );
  add_bttn_mg( ltlbr, cancel_label, "TEXT\\nTEXT", " ", 2 );
  add_txt( ltlbr, "\)][" );
  add_bttn_mg( ltlbr, quotation_label, "\"\"TEXT\\n\"\"TEXT", "\\\"\\\"", 1 );
  add_txt( ltlbr, "\(" );
  add_bttn_mg( ltlbr, cancel_label, "TEXT\\nTEXT", "\\\"\\\"", 2 );
  add_txt( ltlbr, "\)][" );
  add_bttn_mg( ltlbr, comment_label, "//TEXT\\n//TEXT", "//", 1 );
  add_txt( ltlbr, "\(" );
  add_bttn_mg( ltlbr, cancel_label, "TEXT\\nTEXT", "//", 2 );
  add_txt( ltlbr, "\)]" );

}

function set_wtlbr() {

  add_txt( wtlbr, "[" );
  add_bttn( wtlbr, link_label, "[[TEXT]]", "[[", "]]" );
  add_txt( wtlbr, "|" );
  add_bttn( wtlbr, url_label, "[[TEXT|http://]]", "[[", "|http://]]" );
  add_txt( wtlbr, "][" );
  add_bttn( wtlbr, emphasized_label, "\'\'TEXT\'\'", "\\'\\'", "\\'\\'" );
  add_txt( wtlbr, "|" );
  add_bttn( wtlbr, strongly_label, "\'\'\'TEXT\'\'\'", "\\'\\'\\'", "\\'\\'\\'" );
  add_txt( wtlbr, "][" );
  add_bttn( wtlbr, struckout_label, "==TEXT==", "==", "==" );
  add_txt( wtlbr, "][" );
  add_bttn( wtlbr, definition_label, ":WORD:TEXT", ":", ":" );
  add_txt( wtlbr, "][" );
  add_bttn( wtlbr, horizontal_label, "----", "\\n----\\n", "" );
  add_txt( wtlbr, "]" );

}

function set_ttlbr() {

  add_txt( ttlbr, "[" );
  add_bttn( ttlbr, cell_label, "||TEXT", "||", "" );
  add_txt( ttlbr, "][" );
  add_bttn( ttlbr, headingcell_label, "||!TEXT", "!", "" );
  add_txt( ttlbr, "][" );
  add_bttn( ttlbr, rows_label, "||^TEXT", "^", "" );
  add_txt( ttlbr, "][" );
  add_bttn( ttlbr, columns_label, "||>TEXT", ">", "" );
  add_txt( ttlbr, "]" );

}

function set_ptlbr() {

  add_ptxt( "[" );
  add_pbttn( plugin_label, "{{TEXT}}", "{{", "}}" );
  add_ptxt( "][" );
  add_pbttn( br_label, "{{br}}", "{{br}}", "" );
  add_ptxt( "][" );
  add_pbttn( toc_label, "{{toc}}", "\\n{{toc}}\\n", "" );
  add_ptxt( "|" );
  add_pbttn( tochere_label, "{{toc_here}}", "\\n{{toc_here}}\\n", "" );
  add_ptxt( "][" );
  add_pbttn( recent_label, "{{recent\(num\)}}", "\\n{{recent\(20\)}}\\n", "" );
  add_ptxt( "]" );

}

function set_mtlbr() {
  add_txt( mtlbr, "[" );
  add_bttn_mg( mtlbr, display_label, "$$TEXT\\n$$TEXT", "$$", 1 );
  add_txt( mtlbr, "\(" );
  add_bttn_mg( mtlbr, cancel_label, "TEXT\\nTEXT", "\\\\$\\\\$", 2 );
  add_txt( mtlbr, "\)" );
  add_txt( mtlbr, "][" );
  add_bttn( mtlbr, inline_label, "[$TEXT$]", "[$", "$]" );
  add_txt( mtlbr, "]" );
}

function ins_tlbr( tlbr ) {
  tlbr.className = tlbr_class;
  txtarea.parentNode.insertBefore(tlbr, txtarea);
}

END_HELP

  help << <<END_HELP

// main
  var txtarea = document.forms[0].contents;
  var stlbr = document.createElement("div");
  var ltlbr = document.createElement("div");
  var wtlbr = document.createElement("div");
  var ttlbr = document.createElement("div");
  var ptlbr = document.createElement("div");

  tlbr_ids = new Array( "lines_help", "words_help", "table_help", "plugin_help" );
  ltlbr.id = "lines_help";
  wtlbr.id = "words_help";
  ttlbr.id = "table_help";
  ptlbr.id = "plugin_help";

  ltlbr.style.display = "none";
  wtlbr.style.display = "none";
  ttlbr.style.display = "none";
  ptlbr.style.display = "none";

  set_stlbr();
  ins_tlbr( stlbr );

  set_ltlbr();
  ins_tlbr( ltlbr );

  set_wtlbr();
  ins_tlbr( wtlbr );

  set_ttlbr();
  ins_tlbr( ttlbr );

  set_ptlbr();
  ins_tlbr( ptlbr );

END_HELP

if @conf.style == "math"
  help << <<END_HELP

  tlbr_ids.push( "math_help" );
  set_showbttn( mathhelp_label, "math_help" );
  var mtlbr = document.createElement("div");
  mtlbr.id = "math_help";
  mtlbr.style.display = "none";
  set_mtlbr();
  ins_tlbr( mtlbr );

END_HELP
end

  help << <<END_HELP

// --></script>
END_HELP
  help
end

def help_add_pbttn(help_txt, help_tps, help_pre, help_suf)
  return unless help_enabled?
  add_edit_proc do
    help = <<END_HELP

<script type="text/javascript"><!--

  var txt = "#{help_txt}";
  var tps = "#{help_tps}";
  var pre = "#{help_pre}";
  var suf = "#{help_suf}";

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
