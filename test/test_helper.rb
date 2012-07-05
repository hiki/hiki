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
end
