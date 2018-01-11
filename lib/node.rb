# rubocop:disable Metrics/AbcSize #

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

  def new_blueprint
    @utils.divider
    @utils.divider

    url = ask("What's the url?")

    # Transform the url in the folder name
    blueprint_folder = folder_name(url)

    # Make sure the folder doesnt already exist
    validate_blueprint_folder(blueprint_folder)

    @utils.divider
    @utils.divider

    # choose template
    choose do |menu|
      menu.prompt = 'Which template?'
      @templates.each do |folder|
        menu.choice(folder.tr('_', '.')) do
          @utils.divider
          @utils.divider
          say "Copying #{folder} ..."
            @template_folder = folder
          end
      end
    end

    copy_blueprint(@template_folder, blueprint_folder)
  end

  def new_build
    build
  end

  def update_build
    build true
  end


  def build(update=false)
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
          commit_changes folder
          link_heroku_app folder if update

          @utils.divider
          @utils.divider

          say "Bootstrapping #{folder} ..."
          create_heroku_app folder unless heroku_app_exists?(folder)
          configure_heroku_addons folder, update
          set_heroku_env_variables folder
          set_local_env_variables folder
          backup_db folder
          publish_to_heroku folder
          setup_heroku_db folder

          enable_heroku_production folder unless update
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
    Settings.add_source! "#{@blueprints_path}/#{folder}/env.yml"
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

  def cleanup_build(folder)
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


  def commit_changes(folder)
    Dir.chdir("#{@build_path}/#{folder}") do
      system "git commit -am 'built complete'"
    end
  end

  def link_heroku_app(folder)
    Dir.chdir("#{@build_path}/#{folder}") do
      system "heroku git:remote -a #{Settings.heroku.app}"
    end
  end

  ## BOOTSTRAP NODE ##
  def heroku_app_exists?(folder)
    return false if Settings.heroku.app.eql? '$heroku_app'
    true
  end

  def create_heroku_app(folder)
    heroku_app = "#{folder_name(Settings.url)}_#{rand(110..350)}".gsub('_','-')

    Dir.chdir("#{@blueprints_path}/#{folder}") do
      say 'updating blueprint'
      system "grep -rl --color  '$heroku_app' * | xargs -I@ sed -i '' 's/$heroku_app/#{heroku_app}/g' @"
    end

    Dir.chdir("#{@build_path}/#{folder}") do
      @utils.divider
      @utils.divider
      say 'creating heroku application'
      @utils.divider
      @utils.divider
      system "heroku create #{heroku_app} -t leonid-io"
    end
  end

  def configure_heroku_addons(folder, update=false)
    Dir.chdir("#{@build_path}/#{folder}") do
      @utils.divider
      @utils.divider
      say 'configuring heroku application'
      @utils.divider
      @utils.divider
      system 'heroku buildpacks:set heroku/nodejs'
      system 'heroku buildpacks:add heroku/ruby'
      Settings.heroku.addons.each do |addon|
        system "heroku addons:create #{addon}"
      end
    end
  end

  def set_heroku_env_variables(folder)
    Dir.chdir("#{@build_path}/#{folder}") do
      @utils.divider
      @utils.divider
      say 'setting global env variables'
      @utils.divider
      @utils.divider
      Settings.env.each do |env_var|
        var_name = env_var[0].to_s
        var_value = env_var[1].to_s
        system "heroku config:set #{var_name}=#{var_value}"
      end
    end
  end

  def set_local_env_variables(folder)
    @utils.divider
    @utils.divider
    say 'setting local env variables'
    @utils.divider
    @utils.divider
    Dir.chdir("#{@build_path}/#{folder}") do
      Settings.env.each do |env_var|
        var_name = env_var[0].to_s
        var_value = env_var[1].to_s
        system "echo #{var_name}=#{var_value} >> .env"
      end
    end
  end

  def backup_db(folder)
    @utils.divider
    @utils.divider
    say 'backing up heroku db'
    @utils.divider
    @utils.divider
    Dir.chdir("#{@build_path}/#{folder}") do
      system 'heroku pg:backups:capture'
    end
  end

  def setup_heroku_db(folder)
    @utils.divider
    @utils.divider
    say 'setting up heroku db'
    @utils.divider
    @utils.divider
    Dir.chdir("#{@build_path}/#{folder}") do
      system 'heroku run rake db:migrate'
      system 'heroku run rake db:seed'
      system 'heroku run rake genesis:colors:setup'
    end
  end

  def publish_to_heroku(folder)
    Dir.chdir("#{@build_path}/#{folder}") do
      system 'git push -f heroku master'
    end
  end

  def enable_heroku_production(folder)
    Dir.chdir("#{@build_path}/#{folder}") do
      system "heroku domains:add #{Settings.url}"
      system 'heroku ps:resize web=hobby'
    end
  end
end

# rubocop:enable Metrics/AbcSize #
