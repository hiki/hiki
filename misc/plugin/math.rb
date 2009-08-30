def math_latex_download
  params     = @cgi.params
  page       = (params['p'] || '')
  file_name  = (params['file_name'] || '')
  image_file = "#{@cache_path}/math_latex/#{escape(page)}/#{escape(file_name)}"
  mime_type  = "image/png"

  header = {}
  header['Content-Type'] = mime_type
  header['Last-Modified'] = CGI.rfc1123_date(File.mtime(image_file.untaint))
  header['Content-Disposition'] = %Q|filename="#{file_name.to_sjis}"|
  ::Hiki::Response.new(File.open(image_file.untaint, "rb").read, 200, header)
end

add_header_proc {
  <<-EOS
    <style type="text/css"><!--
      img.math {
        vertical-align: middle;
      }

      div.displaymath {
        text-align: center;
      }
    --></style>
  EOS
}

def math_init
  @conf['math.latex.ptsize'] ||= '12'
  @conf['math.latex.documentclass'] ||= 'report'
  @conf['math.latex.preamble'] ||= ''
  @conf['math.latex.log'] ||= false
  @conf['math.latex.secure'] ||= true
  unless (@conf['math.latex.secure'] || true) then
    @conf['math.latex.latex'] ||= 'latex %.tex'
    @conf['math.latex.dvips'] ||= 'dvips %.dvi'
    @conf['math.latex.convert'] ||= 'convert -antialias -transparent white -trim %.ps %.png'
  end
  nil
end

if @mode != 'conf' and @mode != 'saveconf' then
  add_body_enter_proc do
    math_init
  end
end

def math_clear_cache
  cache_path = "#{@conf.cache_path}/math_latex".untaint
  Dir.glob("#{cache_path}/*") do |ent|
    require 'fileutils'
    ent.untaint
    FileUtils.rm_rf(ent) if File.directory?(ent)
  end
end

def saveconf_math
  if @mode == 'saveconf' then
    @conf['math.latex.ptsize'] = @cgi.params['math.latex.ptsize']
    @conf['math.latex.documentclass'] = @cgi.params['math.latex.documentclass']
    @conf['math.latex.preamble'] = @cgi.params['math.latex.preamble']
    @conf['math.latex.log'] = (@cgi.params['math.latex.log'] == 'true')
    unless (@conf['math.latex.secure'] || true) then
      @conf['math.latex.latex'] = @cgi.params['math.latex.latex']
      @conf['math.latex.dvips'] = @cgi.params['math.latex.dvips']
      @conf['math.latex.convert'] = @cgi.params['math.latex.convert']
    end
    math_init
    if @cgi.params['math.latex.cache_clear'] == 'true' then
      math_clear_cache
    end
  end
end

add_conf_proc('math', 'math style') do
  saveconf_math
  math_init

  str = <<-HTML
  <h3 class="subtitle">#{label_math_latex_ptsize}</h3>
  <p><input type="text" name="math.latex.ptsize" value="#{@conf['math.latex.ptsize']}" size="5">pt</p>
  <h3 class="subtitle">#{label_math_latex_documentclass}</h3>
  <p><input type="text" name="math.latex.documentclass" value="#{@conf['math.latex.documentclass']}" size="20"></p>
  <h3 class="subtitle">#{label_math_latex_preamble}</h3>
  <p><textarea name="math.latex.preamble" cols="60" rows="8">#{h(@conf['math.latex.preamble'])}</textarea></p>
  <h3 class="subtitle">#{label_math_latex_log}</h3>
  <p><input type="checkbox" name="math.latex.log" value="true"#{@conf['math.latex.log'] ? ' checked="checked"' : ""}>#{label_math_latex_log_description}</p>
  <h3 class="subtitle">#{label_math_latex_cache_clear}</h3>
  <p><input type="checkbox" name="math.latex.cache_clear" value="true">#{label_math_latex_cache_clear_description}</p>
  HTML

  # NOTE that following items are disabled now because it is not
  # suitable for setting these through CGI.  If you want to configure
  # these values on your head, do set the math.latex.secure to false.
  unless @conf['math.latex.secure'] then
    str += <<-HTML
    <h3 class="subtitle">#{label_math_latex_latex}</h3>
    <p><input type="text" name="math.latex.latex" value="#{h(@conf['math.latex.latex'])}"></p>
    <h3 class="subtitle">#{label_math_latex_dvips}</h3>
    <p><input type="text" name="math.latex.dvips" value="#{h(@conf['math.latex.dvips'])}"></p>
    <h3 class="subtitle">#{label_math_latex_convert}</h3>
    <p><input type="text" name="math.latex.convert" value="#{h(@conf['math.latex.convert'])}"></p>
    HTML
  end
  str
end
