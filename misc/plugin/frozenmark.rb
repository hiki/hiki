# $Id: frozenmark.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $

def frozenmark_message; 'このページは凍結されています。'; end

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
