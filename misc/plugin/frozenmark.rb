# $Id: frozenmark.rb,v 1.4 2005-03-03 15:53:55 fdiary Exp $
# Copyright (C) 2003 OZAWA Sakuro <crouton@users.sourceforge.jp>

def about_frozenmark
  <<-EOS
!Description
When this plugin is installed, an message telling the page is frozen is displayed on all frozen pages.
  EOS
end

add_page_attribute_proc {
  if @db.is_frozen?(@page) then
    <<-EOS
    <div class="frozenmark">
      <span class="frozenmark-message">#{frozenmark_message}</span>
    </div>
    EOS
  else
    ''
  end
}
