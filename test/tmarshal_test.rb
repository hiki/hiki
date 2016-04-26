
require "test_helper"
require "tmarshal"
require "stringio"

class TMarshal_Unit_Tests < Test::Unit::TestCase
  class A;end

  def setup
    @input = [true, false, nil, Object, :a, /x/, 1..2, 3...4, Time.gm(1970), "ABC", {"a"=>1, "b"=>2, "c"=>3}]
  end

  def teardown
    @io.close if @io && !@io.closed?
  end

  def test_string
    assert_equal('"123"', TMarshal::dump("123"))
  end

  def test_array
    assert_equal("[\n]", TMarshal::dump([]))
    assert_equal("[\n1,\n2,\n3,\n]", TMarshal::dump([1,2,3]))
  end

  def test_numeric
    assert_equal("123", TMarshal::dump(123))
    assert_equal("123123123123123", TMarshal::dump(123123123123123))
    assert_equal("1.23", TMarshal::dump(1.23))
    assert_equal("1.23e+45", TMarshal::dump(1.23e+45))
  end

  def test_hash
    assert_equal("{\n}", TMarshal::dump({}))
    assert_equal("{\n\"a\" => 1,\n\"b\" => 2,\n}", TMarshal::dump({"a"=>1, "b"=>2}))
  end

  def test_true
    assert_equal("true", TMarshal::dump(true))
  end

  def test_false
    assert_equal("false", TMarshal::dump(false))
  end

  def test_nil
    assert_equal("nil", TMarshal::dump(nil))
  end

  def test_range
    assert_equal("1..3", TMarshal::dump(1..3))
    assert_equal("1...3", TMarshal::dump(1...3))
  end

  def test_time
    assert_equal("Time.at(0)", TMarshal::dump(Time.gm(1970)))
  end

  def test_else
    assert_raise(RuntimeError) {TMarshal::dump(A.new)}
  end

  def test_load_string
    @io = StringIO.new
    TMarshal::dump(@input, @io)
    @io.rewind
    str = @io.read
    assert_equal(@input, TMarshal::load(str))
    @io.close
  end

  def test_load_stringio
    @io = StringIO.new
    TMarshal::dump(@input, @io)
    @io.rewind
    assert_equal(@input, TMarshal::load(@io))
  end

  def test_load_else
    assert_raise(RuntimeError) {TMarshal::load([])}
  end
end
