require 'singleton'
require 'amrita/ams'

module Amrita
  # a mod_ruby handler for amrita-script 
  class AmsHandler
    include Apache
    include Singleton

    def handler(r)
      if r.method_number == M_OPTIONS
	r.allowed |= (1 << M_GET)
	r.allowed |= (1 << M_POST)
	return DECLINED
      end
      if r.finfo.mode == 0
	return NOT_FOUND
      end
      if r.allow_options & OPT_EXECCGI == 0
	r.log_reason("Options ExecCGI is off in this directory", r.filename)
	return FORBIDDEN
      end
      unless r.finfo.executable?
	r.log_reason("file permissions deny server execution", r.filename)
	return FORBIDDEN
      end
      r.setup_cgi_env
      filename = r.filename.dup.untaint
      Apache.chdir_file(filename)

      $amrita_template_path = filename

      t = Amrita::AmsTemplate[filename]
      t.use_compiler = true
      
      r.content_type = "text/html"
      r.send_http_header
      t.expand(r)

      return OK
    end
  end
end
