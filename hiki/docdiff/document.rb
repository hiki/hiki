# Document class, a part of DocDiff
# 2004-01-14.. Hisashi MORITA

require 'docdiff/charstring'

class EncodingDetectionFailure < Exception
end
class EOLDetectionFailure < Exception
end

class Document

  def initialize(str, enc = nil, e = nil)
    @body = str
    @body.extend CharString
    if enc
      @body.encoding = enc
    else
      guessed_encoding = CharString.guess_encoding(str)
      if guessed_encoding == "UNKNOWN"
        raise EncodingDetectionFailure, "encoding not specified, and auto detection failed."
        # @body.encoding = 'ASCII' # default to ASCII <= BAD!
      else
        @body.encoding = guessed_encoding
      end
    end
    if e
      @body.eol = e
    else
      guessed_eol = CharString.guess_eol(str)
      if guessed_eol == "UNKNOWN"
        raise EOLDetectionFailure, "eol not specified, and auto detection failed."
        # @body.eol = 'LF' # default to LF
      else
        @body.eol = guessed_eol
      end
    end
  end
  def encoding()
    @body.encoding
  end
  def encoding=(cs)
    @body.encoding = cs
  end
  def eol()
    @body.eol
  end
  def eol=(eolstr)
    @body.eol = eolstr
  end

  def split_to_line()
    @body.split_to_line
  end
  def split_to_word()
    @body.split_to_word
  end
  def split_to_char()
    @body.split_to_char
  end
  def split_to_byte()
    @body.split_to_byte
  end

  def count_line()
    @body.count_line
  end
  def count_blank_line()
    @body.count_blank_line
  end
  def count_empty_line()
    @body.count_empty_line
  end
  def count_graph_line()
    @body.count_graph_line
  end

  def count_word()
    @body.count_word
  end
  def count_latin_word()
    @body.count_latin_word
  end
  def count_ja_word()
    @body.count_ja_word
  end
  def count_valid_word()
    @body.count_valid_word
  end
  def count_latin_valid_word()
    @body.count_latin_valid_word
  end
  def count_ja_valid_word()
    @body.count_ja_valid_word
  end

  def count_char()
    @body.count_char
  end
  def count_blank_char()
    @body.count_blank_char
  end
  def count_graph_char()
    @body.count_graph_char
  end
  def count_latin_blank_char()
    @body.count_latin_blank_char
  end
  def count_latin_graph_char()
    @body.count_latin_graph_char
  end
  def count_ja_blank_char()
    @body.count_ja_blank_char
  end
  def count_ja_graph_char()
    @body.count_ja_graph_char
  end

  def count_byte()
    @body.count_byte
  end

  def eol_char()
    @body.eol_char
  end

end  # class Document
