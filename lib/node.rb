require 'singleton'
require 'config'
require 'byebug'
require './lib/helpers/utils'

class Node
  include Singleton

  def initialize
    @utils = Utils.instance

    @schematics_path = @utils.root + '/schematics'
    @template_path = @utils.root + '/templates'

    @blueprints_path = File.expand_path('~/dev/blueprints')
    @source_path = File.expand_path('~/dev/sources')
    @build_path = File.expand_path('~/dev/builds')

    @blueprints = Dir.entries(@blueprints_path) - %w[. .. .git README.md .DS_Store]
    @templates = Dir.entries(@template_path) - %w[. .. .DS_Store]
  end

  def new
    url = ask('What is the url?')
    @utils.divider

    # Transform the url in the folder name
    blueprint_folder = folder_name(url)

    # Make sure the folder doesnt already exist
    validate_blueprint_folder(blueprint_folder)

    # choose template
    choose do |menu|
      menu.prompt = 'Which template?'
      @templates.each do |folder|
        menu.choice(folder.tr('_', '.')) do
          @utils.divider
          say "Copying #{folder} ..."
          @template_folder = folder
        end
      end
    end

    copy_blueprint(@template_folder, blueprint_folder)
  end

  def build
    choose do |menu|
      menu.prompt = 'Which node?'
      @blueprints.each do |folder|
        menu.choice(folder.tr('_', '.')) do
          @utils.divider
          say "Building #{folder} ..."
          load_config folder
          remove_build folder
          copy_source_to folder
          cleanup_build folder
          rename_source_files folder
        end
      end
    end
  end

  def bootstrap
    choose do |menu|
      menu.prompt = 'Which node?'
      @blueprints.each do |folder|
        menu.choice(folder.tr('_', '.')) do
          @utils.divider
          say "Bootstrapping #{folder} ..."
          load_config folder
          validate_heroku_app folder
          create_heroku_app folder
        end
      end
    end
  end

  private

  ## NEW SECTION ##
  def folder_name(url)
    # removing the www. and replacing dots with underscores
    url.gsub('www.', '').tr('.', '_')
  end

  def validate_blueprint_folder(new_blueprint_folder)
    existing_folder = @blueprints.select { |folder| folder == new_blueprint_folder }

    unless existing_folder.empty?
      @utils.divider
      say 'Aborting Operation'
      say "folder: #{new_blueprint_folder} already exists under '~/dev/blueprints'"
      exit
    end
  end

  def copy_blueprint(template_folder, blueprint_folder)
    say "adding blueprint to: #{blueprint_folder} under ~/dev/blueprints"
    FileUtils.copy_entry "#{@template_path}/#{template_folder}", "#{@blueprints_path}/#{blueprint_folder}"
  end

  ## BUILD SECTION ##
  def load_config(folder)
    # Load Blueprint & Schematic
    Config.load_and_set_settings "#{@blueprints_path}/#{folder}/setup.yml"
    Settings.add_source! "#{@schematics_path}/#{Settings.schematic}.yml"
    Settings.reload!

    say "- schematic: #{Settings.schematic}"
    say "- source folder: #{Settings.source.folder}"
  end

  def remove_build(folder)
    FileUtils.rm_rf "#{@build_path}/#{folder}"
  end

  def copy_source_to(folder)
    FileUtils.copy_entry "#{@source_path}/#{Settings.source.folder}", "#{@build_path}/#{folder}"
  end

  def cleanup_build (folder)
    Dir.chdir("#{@build_path}/#{folder}") do
      system 'git remote rm origin'
      system 'git remote rm heroku'
      system 'git branch | grep -v "master" | xargs git branch -D'
      system 'rm .env'
    end
  end

  def rename_source_files(folder)
    excluded_files='genesis.rb,README.md,.DS.Store'
    excluded_folders = 'frontend,node_modules'
    Dir.chdir("#{@build_path}/#{folder}") do
      system "grep -rl --color --exclude-dir={#{excluded_folders}} --exclude={#{excluded_files}} '#{Settings.source.url}' * | xargs -I@ sed -i '' 's/#{Settings.source.url}/#{Settings.url}/g' @"
      system "grep -rl --color --exclude-dir={#{excluded_folders}} --exclude={#{excluded_files}} '#{Settings.source.name}' * | xargs -I@ sed -i '' 's/#{Settings.source.name}/#{Settings.name}/g' @"
      system "grep -rl --color --exclude-dir={#{excluded_folders}} --exclude={#{excluded_files}} '#{Settings.source.name.capitalize}' * | xargs -I@ sed -i '' 's/#{Settings.source.name.capitalize}/#{Settings.name.capitalize}/g' @"
    end
  end

  ## BOOTSTRAP NODE ##
  def validate_heroku_app (folder)
    unless Settings.heroku.app.eql? '$heroku_app'
      say 'Aborting Operation'
      say "App already bootstrapped as : #{Settings.heroku.app}. Check setup.yml under ~/dev/blueprints/#{folder} '"
      exit
    end
  end

  def create_heroku_app (folder)
    heroku_app = "#{folder_name(Settings.url)}_#{rand(110..350)}".gsub('_','-')

    Dir.chdir("#{@blueprints_path}/#{folder}") do
      say 'updating blueprint'
      system "grep -rl --color  '$heroku_app' * | xargs -I@ sed -i '' 's/$heroku_app/#{heroku_app}/g' @"
    end

    Dir.chdir("#{@build_path}/#{folder}") do
      say 'creating heroku app ...'
      system "heroku create #{heroku_app} -t leonid-io"
    end
  end
end
