require 'rast'

def rast_register( page = @page, force = false )
  db_path = ( @conf.options['rast-register.db_path'] || "#{@cache_path}/rast" ).untaint
  rast_make_db( db_path ) unless File.exist?( db_path )
  uri = "#{@conf.index_url}?#{page.escape}"
  last_modified = @db.get_attribute( page, :last_modified ).strftime( "%FT%T" )
  options = {"properties" => ['last_modified']}
  Rast::DB.open( db_path, Rast::DB::RDWR, "sync_threshold_chars" => 500000) do |db|
    result = db.search( "uri = #{uri}", options )
    item, = result.items
    if item
      if force || item.properties[0] < last_modified
        db.delete( item.doc_id )
      else
        return
      end
    end
  end
  title = @db.get_attribute( page, :title )

  body = ''
  body << "#{page} " unless title.empty? || title == page
  body << @db.load(page) 
  properties = {
    "title" => title,
    "uri" => uri,
    "last_modified" => last_modified,
  }
  Rast::DB.open( db_path, Rast::DB::RDWR, "sync_threshold_chars" => 500000) do |db|
    db.register( body, properties )
  end
end

def rast_delete
  db_path = ( @conf.options['rast-register.db_path'] || "#{@cache_path}/rast" ).untaint
  options = {"properties" => ['uri']}
  return unless File.exist?( db_path )
  uri = "#{@conf.index_url}?#{@page.escape}"
  Rast::DB.open( db_path, Rast::DB::RDWR, "sync_threshold_chars" => 500000) do |db|
    result = db.search("uri = #{uri}", options)
    result.items.each do |item|
      db.delete(item.doc_id)
    end
  end
end

def rast_make_db( db_path )
  db_options = {
    'encoding' => 'euc_jp',
    'preserve_text' => true,
    'properties' => [
      {
        'name' => 'uri',
        'type' => Rast::PROPERTY_TYPE_STRING,
        'search' => true,
        'text_search' => true,
        'full_text_search' => false,
        'unique' => false,
      },
      {
        'name' => 'title',
        'type' => Rast::PROPERTY_TYPE_STRING,
        'search' => false,
        'text_search' => true,
        'full_text_search' => true,
        'unique' => false,
      },
      {
        'name' => 'last_modified',
        'type' => Rast::PROPERTY_TYPE_DATE,
        'search' => true,
        'text_search' => false,
        'full_text_search' => false,
        'unique' => false,
      }
    ]
  }
  Rast::DB.create( db_path, db_options )
end

add_update_proc do
  rast_register
end

add_delete_proc do
  rast_delete
end

if !@conf['rast_register.hideconf'] && (@mode == 'conf' || @mode == 'saveconf')
  add_conf_proc('rast_register', @rast_register_conf_label) do
    str = <<-HTML
<h3 class="subtitle">#{@rast_register_conf_header}</h3>
<p>
<input type="checkbox" name="rast_register_rebuild" value="1">
#{@rast_register_conf_description}
</p>
HTML
    if @mode == 'saveconf'
      unless @cgi['rast_register_rebuild'].empty?
	encoding = @conf.options['rast.encoding'] || 'euc_jp'
	@db.page_info.each do |i|
	  page = i.keys[0]
	  rast_register( page, true )
	end
	str << "<p>Done.</p>\n"
      end
    end
    str
  end
end
