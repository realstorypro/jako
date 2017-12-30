require 'singleton'

class Utils
  include Singleton

  def divider
    puts '----------------------------------------------------------'
  end

  def root
    root = File.expand_path '../..', __FILE__
    root.gsub('/lib','')
  end

end
