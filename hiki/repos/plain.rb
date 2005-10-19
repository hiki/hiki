require 'hiki/repos/default'
require 'fileutils'

module Hiki
  class HikifarmReposPlain < HikifarmReposBase
    def setup
      Dir.mkdir(@root) if not File.exists?(@root)
    end

    def imported?(wiki)
      File.directory?("#{@root}/#{wiki}")
    end

    def import(wiki)
      FileUtils.mkdir("#{@root}/#{wiki}")
      Dir.glob("#{@data_root}/#{wiki}/text/*") do |orig|
        orig.untaint
        FileUtils.mkdir("#{@root}/#{wiki}/#{File.basename(orig)}")
        FileUtils.cp(orig, "#{@root}/#{wiki}/#{File.basename(orig)}/1")
      end

      File.open("#{@data_root}/#{wiki}/text/.wiki", 'w') do |f|
        f.print wiki
      end
    end

    def update(wiki)
      raise NotImplementedError
    end
  end

  class ReposPlain < ReposBase
    def commit(page, log = nil)
      wiki = File.read("#{@data_path}/text/.wiki")

      dir = "#{@root}/#{wiki.untaint}/#{page.escape.untaint}"

      Dir.mkdir(dir) if not File.exists?(dir)
      FileUtils.rm("#{dir}/.removed", {:force => true})

      rev = last_revision(page) + 1

      FileUtils.cp("#{@data_path}/text/#{page.escape.untaint}", "#{dir}/#{rev}")
    end

    def delete(page, log = nil)
      wiki = File.read("#{@data_path}/text/.wiki")
      File.open("#{@root}/#{wiki.untaint}/#{page.escape.untaint}/.removed", 'w'){|f|}
    end

    def get_revision(page, revision)
      wiki = File.read("#{@data_path}/text/.wiki")
      File.read("#{@root}/#{wiki.untaint}/#{page.escape.untaint}/#{revision.to_i}")
    end

    def revisions(page)
      wiki = File.read("#{@data_path}/text/.wiki")
      revs = []
      Dir.glob("#{@root}/#{wiki.untaint}/#{page.escape.untaint}/*").each do |file|
        revs << [File.basename(file).to_i, File.mtime(file.untaint).localtime.to_s, '', '']
      end
      revs.sort_by{|e| -e[0]}
    end


    private
    def last_revision(page)
      wiki = File.read("#{@data_path}/text/.wiki")
      Dir.glob("#{@root}/#{wiki.untaint}/#{page.escape.untaint}/*").map{|f| File.basename(f)}.sort_by{|f| -f.to_i}[0].to_i
    end
  end
end
