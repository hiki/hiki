def math_latex_download
  params     = @cgi.params
  page       = (params['p'][0] || '')
  file_name  = (params['file_name'][0] || '')
  image_file = "#{@cache_path}/math_latex/#{page.escape}/#{file_name.escape}"
  mime_type  = "image/png"

  header = Hash::new
  header['Content-Type'] = mime_type
  header['Last-Modified'] = CGI::rfc1123_date(File.mtime(image_file.untaint))
  header['Content-Disposition'] = %Q|filename="#{file_name.to_sjis}"|
  print @cgi.header(header)
  print open(image_file.untaint, "rb").read
  nil
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
