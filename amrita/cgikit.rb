
# This is a interface to cgikit

require 'cgikit'
require 'amrita/template'

class CKAmritaElement < CKElement
  include Amrita
  include Amrita::DictionaryData
  def to_s
    tmpl = TemplateText.new body
    result = ""
    tmpl.expand(result, self)
    result
  end
  
  def amrita_get_data(hid, e, context)
    hid = hid.id2name
    ret = fetch(hid)
    unless ret
      ret = CKBinding.bind(parent, hid) 
    end
    ret
  end
end
