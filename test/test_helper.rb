require "pathname"

module TestHelper

  def root_dir
    Pathname(__FILE__).dirname.parent
  end

  def fixtures_dir
    root_dir + "test" + "fixtures"
  end

  def assert_title(expected)
    within("h1.header") do
      assert_equal(expected, text)
    end
  end

  def check_command(command)
    omit "couldn't find #{command}" unless system("which #{command} > /dev/null")
  end

  def file_name(page)
    File.join(@data_dir, "text", page)
  end

  def write(page, content)
    File.open(file_name(page), "wb") do |f|
      f.print(content)
    end
  end

  def read(page)
    File.open(file_name(page), "rb") do |f|
      f.read
    end
  end
end
