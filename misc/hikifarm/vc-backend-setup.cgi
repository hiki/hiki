#!/usr/bin/env ruby
#
# ● バージョン管理バックエンドセットアップスクリプト ●
#
#  CVS/Subversion をバックエンドとして使うときは、
#  最初にこのスクリプトを実行してください。
#  
#  このスクリプトは、hikifarm.conf のあるディレクトリに
#  コピーして実行してください。
# 
#          

print "Content-Type: text/plain\r\n\r\n"


repos_type = nil
repos_root = nil
data_path = ''
hiki = ''

eval(File.read('hikifarm.conf').untaint)

repos_type ||= 'default'

$:.unshift(hiki)
$:.delete(".") if File.writable?(".")

require "hiki/repos/#{repos_type}"
repos = Hiki::const_get("HikifarmRepos#{repos_type.capitalize}").new(repos_root, data_path)

repos.setup

Dir["#{File.dirname(__FILE__)}/*"].each do |wiki|
  wiki.untaint
  next if not FileTest.directory?(wiki) or FileTest.symlink?(wiki) or not FileTest.file?("#{wiki}/hikiconf.rb")
  repos.import(File.basename(wiki)) unless repos.imported?(File.basename(wiki))
end

puts "リポジトリの作成・インポートが終了しました。"

