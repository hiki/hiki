require 'amrita/node_expand'
require 'amrita/parser'

module Amrita

  class MergeTemplate
    include Amrita::DictionaryData

    def initialize(dir=nil, &block)
      @dir = dir
      if block_given?
        @body = yield
      else
        @body = nil
      end
    end

    def amrita_get_data(key, element, context)
      amrita_expand_element(element, context)
    end

    def amrita_expand_element(e, context)
      case e.hid
      when /(.*)#(.*)/
        fname, data_id = $1, $2
        e = merge_templates(fname, data_id, e, context)
      else
        e.init_body do
          e.body.expand1(self, context)
        end
      end

      if @body
        e.expand(@body, context)
      else
        e
      end
    end

    def merge_templates(fname, data_id, e, context)
      h = read_template(fname)
      ee = h.find {|e| e[:id] == data_id }
      raise "no match for #{data_id}" unless ee
      ee.delete_attr!(:id)
      ee
    end

    def read_template(fname)
      fname = @dir + "/" + fname if @dir
      HtmlParser.parse_file fname
    end
  end


end

