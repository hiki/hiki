# -*- coding: utf-8 -*-
# rubyのパス
@ruby = '/usr/bin/ruby'

# Hikiのインストールパス
@hiki = '/home/foo/src/hiki'

# RSSに含めるHikiFarmの説明
@hikifarm_description = 'HogeHogeHikiFarm'

# 作成したWikiサイトにあらかじめ入れたいドキュメントがあるディレクトリ
@default_pages_path = "#{@hiki}/data/text"

# データを入れるディレクトリ
# この下に各Wiki名のディレクトリが掘られる
@data_root = '/home/foo/var/hiki'

# デフォルトの hikiconf.rb を保存するディレクトリ
# hikiconf.rb は各 Wiki ごとに作成する
@farm_root = "#{@hiki}/public"

# バージョン管理なし
@repos_type = nil
@repos_root = nil

#####################################################
# CVS/Subversionバックエンドを使う場合は、
# 設置時に vc-backend-setup.cgi を実行してください。
#####################################################

# CVS バックエンドを使う場合の設定 (ローカルのみ対応)
# @repos_type = 'cvs'
# @repos_root = '/home/foo/var/cvs'

# Subversion バックエンドを使う場合の設定 (ローカルのみ対応)
#   repos_type には 'svn' または 'svnsingle' を設定する。
#   * repos_type が 'svn' の場合、repos_root はただのディレクトリで
#     その下に各 Wiki の名前で、Wiki ごとにリポジトリが作られる。
#   * repos_type が 'svnsingle' だと、repos_root がリポジトリになり、
#     全ての Wiki のデータが単一のリポジトリに格納される。
# @repos_type = 'svn'
# @repos_root = '/home/foo/var/svn'

# バージョン管理として、全バージョンのファイルを保存しておく場合
# @repos_type = 'plain'
# @repos_root = '/home/foo/var/plain'

# HikiFarmのタイトルとCSS、管理者の名前とメール
@title = "HogeHogeWiki"
@css = 'theme/hiki/hiki.css'
@author = 'ほげほげ'
@mail = 'foo@example.com'

# HikiFarm本体の前後に差し込みたいファイルがあれば
# ファイル名を指定する
@header = nil
@footer = nil

# Hiki の CGI ファイル名
# NOTE: Rack では使わない
@cgi_name = 'index.cgi'

# Hiki のファイル添付用 CGI ファイル名
# nil のときは、ファイル添付用CGIは作成しない。
# NOTE: Rack ではファイルは作成しないが名前のみ使用
@attach_cgi_name = 'attach.cgi'

# Hikifarm の template ファイルがあるディレクトリ
@hikifarm_template_dir = "#{@hiki}/misc/hikifarm/template"

# Hikifarm の文字コード
@charset = 'UTF-8'
