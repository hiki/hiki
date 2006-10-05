export_plugin_methods(:its_add_ticket_form, :its_edit_ticket_form, :its_active_tickets, :its_closed_tickets, :its_all_tickets, :its_add_ticket_post, :its_edit_ticket_post)

def its_priority_candidates
  %w(High Normal Low)
end

def its_status_candidates
  %w(New Assigned Reopened Closed)
end

def its_add_ticket_form
  return '' if @conf.use_session && !@session_id
  name = @user || ''

  result = <<EOS
<form action="#{@conf.cgi_name}" method="post">
  <div>
    <input type="hidden" name="c" value="plugin">
    <input type="hidden" name="p" value="#{@page}">
    <input type="hidden" name="plugin" value="its_add_ticket_post">
    Summary:
    <input type="text" name="summary" value="" size="60"><br>
    Priority:
    <select name="priority">
EOS
  its_priority_candidates.each do |i|
    result << %Q|      <option#{i == 'Normal' ? ' selected' : ''}>#{i.escapeHTML}</option>|
  end
  result << <<EOS
    </select><br>
    Version:
    <input type="text" name="version" value="" size="6"><br>
    Reporter:
    <input type="text" name="reporter" value="#{name.escapeHTML}" size="10"><br>
    Description:
    <textarea name="description" cols="60" rows="10"></textarea><br>
    <input type="hidden" name="session_id" value="#{@session_id}">
    <input type="submit" value="Submit">
  </div>
</form>
EOS
  result
end

def its_edit_ticket_form
  return '' if @conf.use_session && !@session_id

  ticket = its_parse_ticket( @page )
  return '' unless ticket
  name = @user || ''
  result = <<EOS
<form action="#{@conf.cgi_name}" method="post">
  <div>
    Name:
    <input type="text" name="name" value="#{name.escapeHTML}" size="10"><br>
    Comment:<br>
    <textarea name="comment" cols="60" rows="8"></textarea>
  </div>
  <div>Change Properties</div>
  <div>
    <input type="hidden" name="c" value="plugin">
    <input type="hidden" name="p" value="#{@page}">
    <input type="hidden" name="plugin" value="its_edit_ticket_post">
    Priority:
    <select name="priority">
EOS
  its_priority_candidates.each do |i|
    result << %Q|      <option#{i == ticket[:priority] ? ' selected' : ''}>#{i.escapeHTML}</option>|
  end
  result << <<EOS
    </select><br>
    Status:
    <select name="status">
EOS
  its_status_candidates.each do |i|
    result << %Q|      <option#{i == ticket[:status] ? ' selected' : ''}>#{i.escapeHTML}</option>|
  end
  result << <<EOS
    </select><br>
    Version:
    <input type="text" name="version" value="#{ticket[:version]}" size="6"><br>
    Milestone:
    <input type="text" name="milestone" value="#{ticket[:milestone]}" size="6"><br>
    Assigned to:
    <input type="text" name="assigned" value="#{ticket[:assigned]}" size="10"><br>
    <input type="hidden" name="session_id" value="#{@session_id}">
    <input type="submit" value="Submit">
  </div>
</form>
EOS
  result
end

def its_active_tickets( num = nil )
  @its_tickets ||= its_get_tickets
  its_view_tickets(@its_tickets.select {|i| /^Closed$/i !~ i[:status]}.sort_by{|a| [its_priority_candidates.index(a[:priority]), -a[:num]]}, num)
end

def its_closed_tickets( num = nil )
  @its_tickets ||= its_get_tickets
  its_view_tickets(@its_tickets.select {|i| /^Closed$/i =~ i[:status]}.sort_by{|a| -a[:num]}, num)
end

def its_all_tickets( num = nil )
  @its_tickets ||= its_get_tickets
  its_view_tickets(@its_tickets.sort_by{|a| -a[:num]}, num)
end

def its_view_tickets( tickets, num = nil )
  ret = <<-EOS
    <table border="1" style="font-size: small; width: 100%;">
      <tr><th>No.</th><th>Summary</th><th>Version</th><th>Milestone</th><th>Priority</th><th>Reporter</th><th>Created</th></tr>
    EOS
  (num ? tickets[0...num.to_i] : tickets).each do |i|
    ret << %Q|      <tr><td>#{hiki_anchor("Ticket-#{i[:num]}", i[:num])}</td><td>#{hiki_anchor("Ticket-#{i[:num]}", i[:summary].escapeHTML)}</td><td>#{i[:version].escapeHTML}</td><td>#{i[:milestone].escapeHTML}</td><td>#{i[:priority].escapeHTML}</td><td>#{i[:reporter].escapeHTML}</td><td>#{i[:created].escapeHTML}</td></tr>\n|
  end
  ret << "    </table>\n"
  ret
end

def its_parse_ticket( page )
  begin
    text = @db.load(page)
    num = /^Ticket-(\d+)/.match(page)[1].to_i
    summary = /^!(.+)/ =~ text ? $1.strip : ''
    priority = /^:Priority:(.*)/ =~ text ? $1.strip : ''
    reporter = /^:Reporter:(.*)/ =~ text ? $1.strip : ''
    status = /^:Status:(.*)/ =~ text ? $1.strip : ''
    assigned = /^:Assigned to:(.*)/ =~ text ? $1.strip : ''
    created = /^:Created:(.*)/ =~ text ? $1.strip : ''
    version = /:Version:(.*)/ =~ text ? $1.strip : ''
    milestone = /:Milestone:(.*)/ =~ text ? $1.strip : ''

    { :num => num,
      :summary => summary,
      :priority => priority,
      :reporter => reporter,
      :status => status,
      :assigned => assigned,
      :created => created,
      :version => version,
      :milestone => milestone, }
  rescue
    nil
  end
end

def its_get_tickets
  pages = @db.page_info.collect{|i| i.keys[0]}.select {|i| /^Ticket-\d+$/ =~ i}
  tickets = pages.collect {|page| its_parse_ticket( page ) }
  tickets.compact
end

def its_add_ticket_post
  return '' if @conf.use_session && @session_id != @cgi['session_id']

  priority = @cgi['priority']
  version = @cgi['version']
  reporter = @cgi['reporter']
  summary = @cgi['summary']
  description = @cgi['description']
  return true if priority.empty? || summary.empty? || description.empty?
  status = 'New'
  assigned = '?'
  milestone = '?'
  @its_tickets ||= its_get_tickets
  last_ticket = @its_tickets.sort{|a,b| a[:num] <=> b[:num]}.last
  num = last_ticket ? last_ticket[:num].succ : 1
  page = "Ticket-#{num}"
  current_text = load( page )
  md5hex = @db.md5hex( page )
  text = <<EOS
! #{its_escape(summary)}

:Priority:#{its_escape(priority)}
:Reporter:#{its_escape(reporter)}
:Status:#{its_escape(status)}
:Assigned to:#{its_escape(assigned)}
:Version:#{its_escape(version)}
:Milestone:#{its_escape(milestone)}
:Created:#{Time.now.strftime('%Y-%m-%d')}

!! Description

#{its_escape(description)}

----
!! Changelog
{{its_edit_ticket_form}}
EOS
  text << current_text if current_text
  @page = page
  save( page, text, md5hex )
end

def its_edit_ticket_post
  return '' if @conf.use_session && @session_id != @cgi['session_id']

  result = "\n"
  flag = false
  begin
    text = load(@page)
  rescue
    return true
  end
  name = @cgi['name']
  name = 'anonymous' if name.empty?
  comment = @cgi['comment'].sub(/\A[\r\n]*/, '').sub(/[\r\n]*\z/, "\n")
  priority = @cgi['priority']
  status = @cgi['status']
  assigned = @cgi['assigned']
  version = @cgi['version']
  milestone = @cgi['milestone']
  return true if priority.empty? || status.empty?

  text = load( @page )
  md5hex = @db.md5hex( @page )

  text.sub!(/^:Priority:.*/i, ":Priority:#{priority}")
  text.sub!(/^:Status:.*/i, ":Status:#{status}")
  text.sub!(/^:Assigned to:.*/i, ":Assigned to:#{assigned}")
  text.sub!(/^:Version:.*/i, ":Version:#{version}")
  text.sub!(/^:Milestone:.*/i, ":Milestone:#{milestone}")
  unless comment.empty?
    str = @conf.parser.heading( "#{name} (#{format_date(Time::now)})\n", 3 )
    str << comment
    text.sub!(/^\{\{its_edit_ticket_form\}\}/, "#{str}\\&")
  end

  save( @page, text, md5hex )
end

def its_escape( str )
  str.gsub( /\{\{/, "{ {" ).gsub( /\}\}/, "} }" ).strip
end
