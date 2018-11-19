# rubocop:disable Metrics/AbcSize #

require 'singleton'
require 'config'
require 'byebug'
require './lib/helpers/utils'

class Databases
  include Singleton

  def initialize
    @utils = Utils.instance
  end

  def upgrade
    puts "calling upgrade from db tools"
  end
end

# rubocop:enable Metrics/AbcSize #
