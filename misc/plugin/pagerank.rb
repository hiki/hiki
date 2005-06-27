#
# PageRank Hiki plugin ver 0.1.9
# 
# author: ichiyama ryoichi <ir@bellbind.net>
# site: http://kumiki.c.u-tokyo.ac.jp/~ichiyama/cgi-bin/hiki/PageRankPlugin.html
# date: 2004/02/20
#
# [@options configuration]
#  @options["pagerank.algorithm"]: "google-original" or "eigenvalue"
#    PageRank algorithm choice: default "google-original"
#      google-original: PR(A) = (1-d) + d(PR(t1)/C(t1) + ... + PR(tn)/C(tn))
#      eigenvalue: PR(A) = 1 + PR(t1)/C(t1) + ... + PR(tn)/C(tn)
#
#  @options["pagerank.dvalue"]: Float value
#    d value in google-original: default 0.85
#
#  @options["pagerank.tablealign"]: "center" or "left" or "right"
#    PageRank table alignment in PageRank page: default "left"
#
#  @options["pagerank.rankformat"]: sprintf format string
#    PageRank table: default "%2.6f"
#
#  @options["pagerank.pagetitle"]: string
#    PageRank page title: default "PageRank: #{@conf.site_name}"
#
#  @options["pagerank.showfrom"]: true or false
#    show "linked from" column if true: default true
#
#  @options["pagerank.maxpages"]: Integer
#    Max pages in tables. if nil, show all pages: default nil
#
#  @options["pagerank.showtime"]: true or false
#    show computing time if true: default false
#

class PageRank
end
def PageRank.version
  '0.1.9'
end
def PageRank.menu_label
  'PageRank'
end
def PageRank.default_options( conf )
  {
    "pagerank.algorithm" => "google-original",
    "pagerank.dvalue" => 0.85,
    "pagerank.tablealign" => "left",
    "pagerank.rankformat" => "%2.6f",
    "pagerank.pagetitle" => "PageRank: #{conf.site_name}",
    "pagerank.showfrom" => true,
    "pagerank.maxpages" => nil,
    "pagerank.showtime" => false,
  }
end


# Mathematical Algorithms
module PageRankAlgorithms
  # solve simultaneous equations
  # by gaussian elimination
  def solve(matrix, value)
    m = mcopy(matrix)
    v = value.dup
    size = v.size
    vorder = (0...size).to_a
    convertdim(m, vorder)
    frontsolve(m, v)
    backsolve(m, v)
    sortorder(v, vorder)
    v
  end
  
  # copy matrix
  def mcopy(matrix)
    m = []
    matrix.each do |row|
      m << row.dup
    end
    m
  end
    
  # exchange columns as the any diagonal values are none-zero
  def convertdim(m, vorder)
    size = vorder.size
    size.times do |i|
      if m[i][i] == 0.0
        size.times do |j|
          next if i == j
          if m[i][j] != 0.0 and m[j][i] != 0.0
            swapv(vorder, i, j)
            swapmc(m, i, j)
          end
        end
      end
    end
  end
  
  # create upper half triangle
  def frontsolve(m, v)
    size = v.size
    size.times do |i|
      (i + 1).upto(size - 1) do |j|
        next if m[j][i] == 0.0
        pole = m[j][i] / m[i][i]
        size.times do |k|
          m[j][k] -= m[i][k] * pole
        end
        v[j] -= v[i] * pole
      end
    end
  end
  
  # generate result
  def backsolve(m, v)
    size = v.size
    (size-1).downto(0) do |i|
      next if m[i][i] == 0.0
      v[i] /= m[i][i] 
      size.times do |j|
        break if i == j
        v[j] -= m[j][i] * v[i]
      end
    end
    v
  end
   
  # sort as original order
  def sortorder(value, order)
    size = order.size
    (size - 1).downto(0) do |i|
      i.times do |j|
        if order[i] < order[j]
          swapv(order, i, j)
          swapv(value, i, j)
        end         
      end
    end
    value
  end
  
  # swap values in vector v
  def swapv(v, i, j) 
    t = v[i]
    v[i] = v[j]
    v[j] = t
    v
  end
 
  # swap matrix column
  def swapmc(m, i, j)
    m.each do |row|
      swapv(row, i, j)
    end
    m
  end

  # summary of each values in vector v
  def vsum(v)
    value = 0.0
    v.each do |c|
      value += c
    end
    value
  end
  
  # vector div by b
  def vdiv(v, b)
    r = []
    v.each do|c|
      r << c/b
    end
    r
  end
  
  # solve PageRank in link matrix
  # see http://www.kusastro.kyoto-u.ac.jp/~baba/wais/pagerank.html
  def pagerank(linkmatrix)
    lm = mcopy(linkmatrix)
    setdiag(lm, 0)
    weightingrow(lm)
    transpose(lm)
    size = lm.size
    setdiag(lm, -1.0)
    v = [-1.0] * size
    frontsolve(lm, v)
    backsolve(lm, v)
    r = vdiv(v, vsum(v))
    r
  end
  
  # set diagonal line values as v
  def setdiag(m, v)
    m.size.times do |i|
      m[i][i] = v
    end
    m
  end
  
  # matrix of weighted values in each rows
  def weightingrow(linkmatrix)
    size = linkmatrix.size
    size.times do |i|
      row = linkmatrix[i]
      weight = vsum(row)
      next if weight == 0
      size.times do |j|
        c = row[j]
        row[j] =  if c == 0 then 0.0 else c.to_f / weight end
      end
    end
  end
  
  # transpose matrix
  def transpose(m)
    size = m.size 
    size.times do |i|
      (i + 1).upto(size - 1) do |j|
        t = m[i][j]
        m[i][j] = m[j][i]
        m[j][i] = t        
      end
    end
    m
  end
  
  # solve the original PageRank in link matrix
  # see http://www.sem-research.jp/sem/seo/20031022000321.html
  def pagerank0(linkmatrix, d=0.85)
    lm = mcopy(linkmatrix)
    setdiag(lm, 0)
    weightingrow(lm)
    transpose(lm)
    diagvalue = -1.0 / d
    setdiag(lm, diagvalue)
    size = lm.size
    v = [-(1.0 - d) / d] * size
    frontsolve(lm, v)
    backsolve(lm, v)
    v
  end

  # print matrix
  def pm(matrix)
    puts "<pre>"
    matrix.each do |row|
      p row
    end
    puts "</pre>"
  end  
end

# PageRank core functions
class PageRank
  include PageRankAlgorithms

  # get page link matrix
  def get_link_matrix(page_names, db)
    size = page_names.size
    lm = []
    size.times do |i|
      lm << [0] * size
    end
    size.times do |i|
      page_name = page_names[i]
      ref_names = db.get_references(page_name)
      size.times do |j|
        lm[j][i] = 1 if ref_names.include?(page_names[j])
      end
    end
    lm
  end
  
  # calc pageranks
  def get_pagerank(page_names, db, options)
    linkmatrix = get_link_matrix(page_names, db)
    if options["pagerank.algorithm"] == "eigenvalue"
      pagerank = pagerank(linkmatrix)
    else
      d = options["pagerank.dvalue"]
      pagerank = pagerank0(linkmatrix, d)
    end
    pagerank
  end

  # sort page names and pageranks by descending order
  def sort(page_names, pagerank)
    size = page_names.size
    (size - 1).downto(0) do |i|
      i.times do |j|
        if pagerank[i] > pagerank[j]
          swap(page_names, i, j)
          swap(pagerank, i, j)
        end         
      end
    end
  end

  # swap array values
  def swap(a, i, j) 
    t = a[i]
    a[i] = a[j]
    a[j] = t
    a
  end

  # pagerank test
  def test_pagerank_eigen()
    lm = [[0, 1, 1, 1, 1, 0, 1],
          [1, 0, 0, 0, 0, 0, 0],
          [1, 1, 0, 0, 0, 0, 0],
          [0, 1, 1, 0, 1, 0, 0],
          [1, 0, 1, 1, 0, 1, 0],
          [1, 0, 0, 0, 1, 0, 0],
          [0, 0, 0, 0, 1, 0, 0]]
    pr = pagerank(lm)
    pr
  end
end

# show pagerank page: called by hiki menu
def pagerank_page
  header = Hash::new
  header['Last-Modified'] = CGI::rfc1123_date(Time.now)
  header['type']          = 'text/html'
  header['charset']       = @conf.charset
  header['Content-Language'] = @conf.lang
  header['Pragma']           = 'no-cache'
  header['Cache-Control']    = 'no-cache'
  print @cgi.header(header)
  
  options = PageRank.default_options( @conf )
  options.update(@options)
  stylesheet = @conf.theme_url + "/" + @conf.theme + "/" + @conf.theme + ".css"
  align = options["pagerank.tablealign"]
  title = options["pagerank.pagetitle"]
  
  sources = %{
<!DOCTYPE html
    PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=EUC-JP" />
  <meta http-equiv="Content-Language" content="ja" />
  <title id=title>#{title.escapeHTML}</title>
  <link rel="stylesheet" type="text/css" href="#{stylesheet.escapeHTML}" /> 
</head>
<body>
<h1>#{title.escapeHTML}</h1>
<div align="#{align}">
#{pagerank()}
</div>
<hr />
<div class="footer">
Generated by <a href="http://kumiki.c.u-tokyo.ac.jp/~ichiyama/cgi-bin/hiki/PageRankPlugin.html">pagerank.rb</a> #{PageRank.version}
</div>
</body>
</html>
}
  puts sources
  nil
end

# print pagerank table
def pagerank(pagerank_options = @options)
  options = PageRank.default_options( @conf )
  options.update(pagerank_options)
  pr = PageRank.new
  page_names = @db.pages
  start = Time.now
  pagerank = pr.get_pagerank(page_names, @db, options)
  calcsec = Time.now - start
  pr.sort(page_names, pagerank)
  get_rank_table(page_names, pagerank, calcsec, options)
end

# generate HTML table
def get_rank_table(page_names, pagerank, calcsec, options)
  size = page_names.size
  no = []
  showfrom = options["pagerank.showfrom"]
  rankformat = options["pagerank.rankformat"]
  maxpages = options["pagerank.maxpages"]
  showtime = options["pagerank.showtime"]
  
  source = %{<table border="1">}
  source += if showfrom
    %{<tr><th>No.</th><th>Page</th><th>Rank</th><th>Linked from</th></tr>}
  else 
    %{<tr><th>No.</th><th>Page</th><th>Rank</th></tr>}
  end
  size.times do |i|
    break if i == maxpages
    no[i] = i + 1
    no[i] = no[i - 1] if i > 0 and pagerank[i] == pagerank[i - 1]
    page = page_names[i]
    page = hiki_anchor(page.escape, page_name(page))
    rank = sprintf(rankformat, pagerank[i])
    if showfrom
      linked_names = @db.get_references(page_names[i]).collect do |linked_name|
        hiki_anchor(linked_name.escape, page_name(linked_name))
      end
      linked = linked_names.join(", ")
      source += %{<tr><td style="text-align: right">#{no[i].to_s}</td><td>#{page}</td><td style="text-align: right">#{rank}</td><td>#{linked}</td></tr>}
    else
      source += %{<tr><td style="text-align: right">#{no[i].to_s}</td><td>#{page}</td><td style="text-align: right">#{rank}</td></tr>}
    end
  end
  source += %{</table>}
  source += %{<div>Top #{no.size} of #{size} pages</div>} if no.size < size
  source += %{<div>computing time: #{calcsec.to_s} sec.</div>} if showtime
  source
end

# append hiki menu
add_body_enter_proc(Proc.new do
  add_plugin_command('pagerank_page', PageRank.menu_label, {})
end)

# history
# 0.1.9: add options "pagerank.showtime", refine code
# 0.1.8: add options "pagerank.showfrom" and "pagerank.maxpages"
# 0.1.7: use page_name() builtin function as table view
# 0.1.6: optimization 0 value in frontsolve
# 0.1.5: add "Linked from" list
# 0.1.4: self links are ignored
# 0.1.3: fix array creation miss
# 0.1.2: use options
# 0.1.1: fix link matrix generate method 
# 0.1:  newly create plugin

export_plugin_methods(:pagerank_page)
