require "digest/md5"
require "hiki/util"

module Hiki
  class Math_latex
    include Hiki::Util

    def initialize(conf, page)
      @conf = conf
      @page = page

      @cache_path = "#{@conf.cache_path}/math_latex"
      @image_path = "#{@cache_path}/#{escape(@page)}"
      begin
        Dir.mkdir(@cache_path) unless test(?e, @cache_path.untaint)
      rescue Exception
      end

      @ptsize = @conf["math.latex.ptsize"]
      @documentclass = @conf["math.latex.documentclass"]
      @preamble = @conf["math.latex.preamble"]
      @latex = @conf["math.latex.latex"] ||= "latex %.tex"
      @dvips = @conf["math.latex.dvips"] ||= "dvips %.dvi"
      @convert = @conf["math.latex.convert"] ||= "convert -antialias -transparent white -trim %.ps %.png"
      @log = @conf["math.latex.log"]
    end

    def md5(text)
      Digest::MD5.hexdigest(text)
    end

    def prepare_directory
      begin
        Dir.mkdir(@image_path) unless test(?e, @image_path.untaint)
      rescue Exception
      end
    end

    def typeset(text)
      self.prepare_directory()

      filename = md5(text.untaint)
      if !File.exist?("#{@image_path}/#{filename}.png") then
        File.open("#{@image_path}/#{filename}.tex", "w") do |f|
          f.puts('\documentclass[' + @ptsize + "pt]{" + @documentclass + "}")
          f.puts(@preamble)
          f.puts('\pagestyle{empty}')
          f.puts('\begin{document}')
          f.puts(text)
          f.puts('\end{document}')
        end

        begin
          if @log
            log = ">>#{filename}.err 2>&1"
          else
            log = ">/dev/null 2>&1"
          end
          [ @latex, @dvips, @convert ].each do |cmd|
            run = cmd.gsub("%") { filename }
            File.open("#{@image_path}/#{filename}.err", "a"){|f|
              f.puts("cd #{@image_path} && #{run}") } if @log
            raise unless system("cd #{@image_path} && #{run} #{log}")
          end

          %w( tex aux log dvi ps err ).each do |ext|
            next if ext == "err" and @log
            gabage = "#{@image_path}/#{filename}.#{ext}"
            File.delete(gabage) if File.exist?(gabage)
          end
        rescue
          if @log
            "Error: see error log `#{filename}.err'"
          else
            "Error: set @options['tex.log'] = true and see the error log."
          end
        end
      end

      html =  %Q!<img class="math" src="!
      html << %Q!#{@conf.cgi_name}#{cmdstr('plugin', "plugin=math_latex_download;p=#{escape(@page)};file_name=#{escape(filename)}.png")}" !
      html << %Q!alt="#{h(text)}">!
    end

    def text_mode(text)
      return "" unless text
      typeset("$#{text}$")
    end

    def display_mode(text)
      return "" unless text
      typeset("\\[#{text}\\]")
    end
  end
end
