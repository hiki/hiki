#!/usr/bin/ruby
# Character String module.
# To use, include to String, or extend String.
# 2003- Hisashi MORITA

#require 'iconv'
module CharString

  Encodings = Hash.new
  EOLChars = Hash.new  # End-of-line characters, such as CR, LF, CRLF.

  def initialize(string)
=begin unnecessary
#    @encoding = CharString.guess_encoding(string)
#    @eol     = CharString.guess_eol(string)
=end unnecessary
    super
  end

  def encoding()
    @encoding
#     if @encoding
#       @encoding
#     else
#       @encoding = CharString.guess_encoding(self)
#       # raise "encoding is not set.\n"
#     end
  end

  def encoding=(cs)
    @encoding = cs
    extend Encodings[@encoding]  # ; p "Hey, I extended #{Encodings[@encoding]}!"
  end

  def eol()
    @eol
#     if @eol
#       @eol
#     else
#       @eol = CharString.guess_eol(self)
#       # raise "eol is not set.\n"
#     end
  end

  def eol=(e)
    @eol = e
    extend EOLChars[@eol]
  end

  def eol_char()
    if @eol_char
      @eol_char
    else
      nil
#       extend EOLChars[eol]
#       eol_char
    end
  end

  def debug()
    case
    when @encoding  == nil
      raise "@encoding is nil."
    when Encodings[@encoding] == nil
      raise "Encodings[@encoding(=#{@encoding})] is nil."
    when Encodings[@encoding].class != Module
      raise "Encodings[@encoding].class(=#{Encodings[@encoding].class}) is not a module."
    when @eol == nil
      raise "@eol is nil."
    when EOLChars[@eol] == nil
      raise "EOLChars[@eol(=#{@eol})] is nil."
    else
      # should I do some alert?
    end
    ["id: #{self.id}, class: #{self.class}, self: #{self}, ", 
     "module: #{Encodings[@encoding]}, #{EOLChars[@eol]}"].join
  end

  def CharString.register_encoding(mod)
    Encodings[mod::Encoding] = mod
  end

  def CharString.register_eol(mod)
    EOLChars[mod::EOL] = mod
  end

  # returns nil, 'ASCII', 'JIS', 'EUC-JP', 'Shift_JIS', 'UTF-8', or 'UNKNOWN'
  def CharString.guess_encoding(string)
    return nil if string == nil
    result_using_pureruby = CharString.guess_encoding_using_pureruby(string)
    result_using_iconv    = CharString.guess_encoding_using_iconv(string)
    if result_using_pureruby == result_using_iconv
      result_using_pureruby
    else
      "UNKNOWN"
    end
  end

  # returns nil, 'ASCII', 'JIS', 'EUC-JP', 'Shift_JIS', 'UTF-8', or 'UNKNOWN'
  def CharString.guess_encoding_using_pureruby(string)
    return nil if string == nil

    ascii_pat = '[\x00-\x7f]'
    jis_pat   = ['(?:(?:\x1b\x28\x42)', 
                 '|(?:\x1b\x28\x4a)', 
                 '|(?:\x1b\x28\x49)', 
                 '|(?:\x1b\x24\x40)', 
                 '|(?:\x1b\x24\x42)', 
                 '|(?:\x1b\x24\x44))'].join
    eucjp_pat = ['(?:(?:[\x00-\x1f\x7f])', 
                 '|(?:[\x20-\x7e])', 
                 '|(?:\x8e[\xa1-\xdf])', 
                 '|(?:[\xa1-\xfe][\xa1-\xfe])', 
                 '|(?:\x8f[\xa1-\xfe][\xa1-\xfe]))'].join
    sjis_pat  = ['(?:(?:[\x00-\x1f\x7f])', 
                 '|(?:[\x20-\x7e])', 
                 '|(?:[\xa1-\xdf])', 
                 '|(?:[\x81-\x9f][\x40-\x7e])', 
                 '|(?:[\xe0-\xef][\x80-\xfc]))'].join
    utf8_pat  = ['(?:(?:[\x00-\x7f])', 
                 '|(?:[\xc0-\xdf][\x80-\xbf])', 
                 '|(?:[\xe0-\xef][\x80-\xbf][\x80-\xbf])', 
                 '|(?:[\xf0-\xf7][\x80-\xbf][\x80-\xbf][\x80-\xbf]))'].join

    ascii_match_length = string.scan(/#{ascii_pat}/on).join.length
    jis_escseq_count   = string.scan(/#{jis_pat}/on).size
    eucjp_match_length = string.scan(/#{eucjp_pat}/no).join.length
    sjis_match_length  = string.scan(/#{sjis_pat}/no).join.length
    utf8_match_length  = string.scan(/#{utf8_pat}/no).join.length

    case
    when 0 < jis_escseq_count                 # JIS escape sequense found
      guessed_encoding = 'JIS'
    when ascii_match_length == string.length  # every char is ASCII (but not JIS)
      guessed_encoding = 'ASCII'
    else
      case
      when eucjp_match_length < (string.length / 2) && 
           sjis_match_length  < (string.length / 2) && 
           utf8_match_length  < (string.length / 2)
        guessed_encoding = 'UNKNOWN'  # either encoding did not match long enough
      when (eucjp_match_length < utf8_match_length) && 
           (sjis_match_length < utf8_match_length)
        guessed_encoding = 'UTF-8'
      when (eucjp_match_length < sjis_match_length) && 
           (utf8_match_length < sjis_match_length)
        guessed_encoding = 'Shift_JIS'
      when (sjis_match_length < eucjp_match_length) && 
           (utf8_match_length < eucjp_match_length)
        guessed_encoding = 'EUC-JP'
      else
        guessed_encoding = 'UNKNOWN'  # cannot guess at all
      end
    end
    return guessed_encoding
  end

  def CharString.guess_encoding_using_iconv(string)
    valid_as_utf8   = CharString.valid_as("utf-8", string)
    valid_as_sjis   = CharString.valid_as("cp932", string) # not sjis, but cp932
    valid_as_jis    = CharString.valid_as("iso-2022-jp", string)
    valid_as_eucjp  = CharString.valid_as("eucjp", string)
    valid_as_ascii  = CharString.valid_as("ascii", string)
    invalid_as_utf8   = CharString.invalid_as("utf-8", string)
    invalid_as_sjis   = CharString.invalid_as("cp932", string) # not sjis, but cp932
    invalid_as_jis    = CharString.invalid_as("iso-2022-jp", string)
    invalid_as_eucjp  = CharString.invalid_as("eucjp", string)
    invalid_as_ascii  = CharString.invalid_as("ascii", string)
    case
    when string == nil
      nil
    when valid_as_ascii
      "ASCII"
    when valid_as_jis  # Iconv sometimes recognizes JIS for ASCII, ignoring JIS escape sequence.
      "JIS"
    when valid_as_eucjp
      "EUC-JP"
    when valid_as_sjis && invalid_as_utf8 && invalid_as_eucjp && invalid_as_jis
      "Shift_JIS"
    when valid_as_utf8 && invalid_as_sjis && invalid_as_eucjp && invalid_as_jis
      "UTF-8"
    else
      "UNKNOWN"
    end
  end
  def CharString.valid_as(encoding_name, string)
    begin
      Iconv.iconv(encoding_name, encoding_name, string)
    rescue Iconv::IllegalSequence, Iconv::InvalidCharacter, Iconv::OutOfRange
      return false
    else
      return true
    end
  end
  def CharString.invalid_as(encoding_name, string)
    if CharString.valid_as(encoding_name, string)
      false
    else
      true
    end
  end

  def CharString.guess_eol(string)
    # returns 'CR', 'LF', 'CRLF', 'UNKNOWN'(binary), 
    # 'NONE'(1-line), or nil
    return nil if string == nil  #=> nil (argument missing)
    eol_counts = {'CR'   => string.scan(/(\r)(?!\n)/no).size,
                  'LF'   => string.scan(/(?:\A|[^\r])(\n)/no).size,
                  'CRLF' => string.scan(/(\r\n)/no).size}
    eol_counts.delete_if{|eol, count| count == 0}  # Remove missing EOL
    eols = eol_counts.keys
    eol_variety = eols.size  # numbers of flavors found
    if eol_variety == 1          # Only one type of EOL found
      return eols[0]         #=> 'CR', 'LF', or 'CRLF'
    elsif eol_variety == 0       # No EOL found
      return 'NONE'              #=> 'NONE' (might be 1-line file)
    else                         # Multiple types of EOL found
      return 'UNKNOWN'           #=> 'UNKNOWN' (might be binary data)
    end
  end

  # Note that some languages (like Japanese) do not have 'word' or 'phrase', 
  # thus some of the following methods are not 'linguistically correct'.

  def split_to_byte()
    scan(/./nm)
  end

  def count_byte()
    split_to_byte().size
  end

  def split_to_char()
    raise "Encodings[encoding] is #{Encodings[encoding].inspect}: encoding not specified or auto-detection failed." unless Encodings[encoding]
    # raise "EOLChars[eol] is #{EOLChars[eol].inspect}: eol not specified or auto-detection failed." unless EOLChars[eol]
    if eol_char  # sometimes string has no end-of-line char
      scan(Regexp.new("(?:#{eol_char})|(?:.)", 
                      Regexp::MULTILINE, 
                      encoding.sub(/ASCII/i, 'none'))
      )
    else                  # it seems that no EOL module was extended...
      scan(Regexp.new("(?:.)", 
                      Regexp::MULTILINE, 
                      encoding.sub(/ASCII/i, 'none'))
      )
    end
  end

  def count_char()  # eol = 1 char
    split_to_char().size
  end

  def count_latin_graph_char()
    raise "Encodings[encoding] is #{Encodings[encoding].inspect}: encoding not specified or auto-detection failed." unless Encodings[encoding]
    # raise "EOLChars[eol] is #{EOLChars[eol].inspect}: eol not specified or auto-detection failed." unless EOLChars[eol]
    scan(Regexp.new("[#{Encodings[encoding]::GRAPH}]", 
                    Regexp::MULTILINE, 
                    encoding.sub(/ASCII/i, 'none'))
    ).size
  end

  def count_ja_graph_char()
    raise "Encodings[encoding] is #{Encodings[encoding].inspect}: encoding not specified or auto-detection failed." unless Encodings[encoding]
    # raise "EOLChars[eol] is #{EOLChars[eol].inspect}: eol not specified or auto-detection failed." unless EOLChars[eol]
    scan(Regexp.new("[#{Encodings[encoding]::JA_GRAPH}]", 
                    Regexp::MULTILINE, 
                    encoding.sub(/ASCII/i, 'none'))
    ).size
  end

  def count_graph_char()
    count_latin_graph_char() + count_ja_graph_char()
  end

  def count_latin_blank_char()
    scan(Regexp.new("[#{Encodings[encoding]::BLANK}]", 
                    Regexp::MULTILINE, 
                    encoding.sub(/ASCII/i, 'none'))
    ).size
  end

  def count_ja_blank_char()
    scan(Regexp.new("[#{Encodings[encoding]::JA_BLANK}]", 
                    Regexp::MULTILINE, 
                    encoding.sub(/ASCII/i, 'none'))
    ).size
  end

  def count_blank_char()
    count_latin_blank_char() + count_ja_blank_char()
  end

  def split_to_word()
    raise "Encodings[encoding] is #{Encodings[encoding].inspect}: encoding not specified or auto-detection failed." unless Encodings[encoding]
    # raise "EOLChars[eol] is #{EOLChars[eol].inspect}: eol not specified or auto-detection failed." unless EOLChars[eol]
    scan(Regexp.new(Encodings[encoding]::WORD_REGEXP_SRC, 
                    Regexp::MULTILINE, 
                    encoding.sub(/ASCII/i, 'none'))
    )
  end

  def count_word()
    split_to_word().size
  end

  def count_latin_word()
    split_to_word.collect{|word|
      word if Regexp.new("[#{Encodings[encoding]::PRINT}]", 
                         Regexp::MULTILINE, 
                         encoding.sub(/ASCII/i, 'none')).match word
    }.compact.size
  end

  def count_ja_word()
    split_to_word.collect{|word|
      word if Regexp.new("[#{Encodings[encoding]::JA_PRINT}]", 
                         Regexp::MULTILINE, 
                         encoding.sub(/ASCII/i, 'none')).match word
    }.compact.size
  end

  def count_latin_valid_word()
    split_to_word.collect{|word|
      word if Regexp.new("[#{Encodings[encoding]::ALNUM}]", 
                         Regexp::MULTILINE, 
                         encoding.sub(/ASCII/i, 'none')).match word
    }.compact.size
  end

  def count_ja_valid_word()
    split_to_word.collect{|word|
      word if Regexp.new("[#{Encodings[encoding]::JA_GRAPH}]", 
                         Regexp::MULTILINE, 
                         encoding.sub(/ASCII/i, 'none')).match word
    }.compact.size
  end

  def count_valid_word()
    count_latin_valid_word() + count_ja_valid_word()
  end

  def split_to_line()
#     scan(Regexp.new(".*?#{eol_char}|.+", 
#                     Regexp::MULTILINE, 
#                     encoding.sub(/ASCII/i, 'none'))
#     )
    raise "Encodings[encoding] is #{Encodings[encoding].inspect}: encoding not specified or auto-detection failed." unless Encodings[encoding]
    raise "EOLChars[eol] is #{EOLChars[eol].inspect}: eol not specified or auto-detection failed." unless EOLChars[eol]
    if defined? eol_char
      scan(Regexp.new(".*?#{eol_char}|.+", 
                      Regexp::MULTILINE, 
                      encoding.sub(/ASCII/i, 'none'))
      )
    else
      scan(Regexp.new(".+", 
                      Regexp::MULTILINE, 
                      encoding.sub(/ASCII/i, 'none'))
      )
    end
  end

  def count_line()  # this is common to all encodings.
    split_to_line.size
  end

  def count_graph_line()
    split_to_line.collect{|line|
      line if Regexp.new("[#{Encodings[encoding]::GRAPH}" + 
                         "#{Encodings[encoding]::JA_GRAPH}]", 
                         Regexp::MULTILINE, 
                         encoding.sub(/ASCII/, 'none')).match line
    }.compact.size
  end

  def count_empty_line()
    split_to_line.collect{|line|
      line if /^(?:#{eol_char})|^$/em.match line
    }.compact.size
  end

  def count_blank_line()
    split_to_line.collect{|line|
      line if Regexp.new("^[#{Encodings[encoding]::BLANK}" + 
                         "#{Encodings[encoding]::JA_BLANK}]+(?:#{eol_char})?", 
                         Regexp::MULTILINE, 
                         encoding.sub(/ASCII/, 'none')).match line
    }.compact.size
  end

  # load encoding modules
  require 'docdiff/encoding/en_ascii'
  require 'docdiff/encoding/ja_eucjp'
  require 'docdiff/encoding/ja_sjis'
  require 'docdiff/encoding/ja_utf8'

  module CR
    EOL = 'CR'

    def eol_char()
      "\r"
    end

    CharString.register_eol(self)
  end

  module LF
    EOL = 'LF'

    def eol_char()
      "\n"
    end

    CharString.register_eol(self)
  end

  module CRLF
    EOL = 'CRLF'

    def eol_char()
      "\r\n"
    end

    CharString.register_eol(self)
  end

  module NoEOL
    EOL = 'NONE'
    def eol_char()
      nil
    end

    CharString.register_eol(self)
  end

end  # module CharString

# class String
#   include CharString
# end
