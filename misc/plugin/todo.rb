# $Id: todo.rb,v 1.5 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def todo(p, num = 8)
  todo_re = /^(\d\d?)\s+(.+)(\d\d\d\d-\d\d-\d\d)?$/

  todo_list = []

  n = @db.load(p.unescapeHTML) || ''
  n.scan(todo_re) do |i|
    todo_list << {:priority => $1.to_i, :todo => $2}
  end

  todo_list.sort! {|a, b| b[:priority] <=> a[:priority]}

  s= ""
  c = 0
  todo_list.each do |t|
    break if (c += 1) > num
    s << "#{'%02d' % t[:priority]} #{t[:todo].escapeHTML}<br>\n"
  end
  s
end
