require "pathname"

module TestHelper

  def root_dir
    Pathname(__FILE__).dirname.parent
  end

  def fixtures_dir
    root_dir + "test" + "fixtures"
  end
end
