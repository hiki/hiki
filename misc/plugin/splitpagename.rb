def page_name(page)
  pg_title = @db.get_attribute(page, :title)
  page = pg_title if pg_title && pg_title.size > 0
  page.gsub(/([a-z])([A-Z])/, '\1 \2').escapeHTML
end
