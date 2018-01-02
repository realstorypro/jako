require 'singleton'
require './lib/helpers/utils'
require 'yaml'
require 'config'


class Node
  include Singleton

  def initialize
    @utils = Utils.instance
    @blueprints_path = @utils.root + '/nodes/blueprints'
    @schematics_path = @utils.root + '/nodes/schematics'
    @template_path = @utils.root + '/nodes/template'
    @source_path = @utils.root + '/source/gravity'
    @build_path = @utils.root + '/builds'

    @blueprints = Dir.entries(@blueprints_path)
    @blueprints -= %w(. ..)
  end

  def new
    url = ask('What is the url?')
    @utils.divider

    blueprint_folder = folder_name(url)

    # check if the folder exists
    existing_folder = @blueprints.select {|folder| folder == blueprint_folder}

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
      @blueprints.each do |folder|
        menu.choice(folder.tr('_','.')) do
          @utils.divider
          say "Building #{folder} ..."
          load_setup folder
          copy_source_to folder
          rename_source_files folder
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
    # Load Blueprint & Schematic
    Config.load_and_set_settings"#{@blueprints_path}/#{folder}/setup.yml"
    Settings.add_source! "#{@schematics_path}/#{Settings.schematic}.yml"
    Settings.reload!

    say "- schematic: #{Settings.schematic}"
    say "- source: #{Settings.source}"
  end

  def copy_source_to(folder)
    FileUtils.copy_entry @source_path, "#{@build_path}/#{folder}"
  end

  def rename_source_files(folder)
    Dir.chdir("#{@build_path}/#{folder}") do
      # rename the url
      system "grep -rli '#{Settings.replace.url}' * | xargs -I@ sed -i '' 's/#{Settings.replace.url}/#{Settings.url}/g' @"
      system "grep -rli '#{Settings.replace.name}' * | xargs -I@ sed -i '' 's/#{Settings.replace.name}/#{Settings.name}/g' @"
      system "grep -rli '#{Settings.replace.name.capitalize}' * | xargs -I@ sed -i '' 's/#{Settings.replace.name.capitalize}/#{Settings.name.capitalize}/g' @"
    end
  end

end