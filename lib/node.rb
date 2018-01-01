require 'singleton'
require './lib/helpers/utils'
require 'yaml'
require 'config'


class Node
  include Singleton

  def initialize
    @utils = Utils.instance
    @blueprints_path = @utils.root + '/nodes/blueprints'
    @template_path = @utils.root + '/nodes/template'
    @source_path = @utils.root + '/source/gravity'
    @build_path = @utils.root + '/builds'

    @folders = Dir.entries(@blueprints_path)
    @folders -= %w(. ..)
  end

  def new
    url = ask('What is the site url?')
    @utils.divider

    blueprint_folder = folder_name(url)

    # check if the folder exists
    existing_folder = @folders.select {|folder| folder == blueprint_folder}

    unless existing_folder.empty?
      @utils.divider
      say 'Aborting Operation'
      say "folder: #{blueprint_folder} already exists under 'nodes/blueprints'"
      return
    end

    copy_blueprint(blueprint_folder)
  end

  def build
    choose do |menu|
      menu.prompt = 'Which node?'
      @folders.each do |folder|
        menu.choice(folder.tr('_','.')) do
          say "Building #{folder} ..."
          load_setup folder
          # copy_source_to folder

        end
      end
    end
  end


  private
  def folder_name(url)
    # removing the www. and replacing dots with underscores
    url.gsub('www.', '').tr('.', '_')
  end

  def copy_blueprint(blueprint_folder)
    say "adding blueprint to: #{blueprint_folder} under nodes/blueprints"
    FileUtils.copy_entry @template_path, "#{@blueprints_path}/#{blueprint_folder}"
  end

  def load_setup(folder)
    Config.load_and_set_settings"#{@blueprints_path}/#{folder}/setup.yml"
    say "Current Schematic: #{Settings.schematic}"

    # config = YAML.load_file('config/config.yml')
    # puts config['user_data']
  end

  def copy_source_to(folder)
    FileUtils.copy_entry @source_path, "#{@build_path}/#{folder}"
    # code here
  end


end