require 'rake'
require 'yaml'
require 'erb'
require 'fileutils'

namespace :ciinabox do

  #load config
  templates = Dir["templates/**/*.rb"]
  ciinaboxes_dir = ENV['CIINABOXES_DIR'] || 'ciinaboxes'
  ciinabox_name = ENV['CIINABOX'] || ''
  config = YAML.load(File.read("#{ciinaboxes_dir}/#{ciinabox_name}/config/default_params.yml")) if File.exist?("#{ciinaboxes_dir}/#{ciinabox_name}/config/default_params.yml")
  services = YAML.load(File.read("#{ciinaboxes_dir}/#{ciinabox_name}/config/services.yml")) if File.exist?("#{ciinaboxes_dir}/#{ciinabox_name}/config/services.yml")
  services = services['services'] unless services.nil?

  desc('Initialse a new ciinabox environment')
  task :init do |t, args|
    ciinabox_name = get_input("Enter the name of your ciinabox:")
    ciinabox_region = get_input("Enter the Azure region to create your ciinabox (e.g: Australia Southeast):")
    ciinabox_tools_domain = get_input("Enter top level domain (e.g tools.example.com), must exist in Azure DNS Services in the same account:")
    ciinabox_dns_resource_group = get_input("Enter the name of the Azure resource group you created your DNS Zone in:")
    if ciinabox_name == ''
      puts 'You must enter a name for you ciinabox'
      exit 1
    end
    create_dirs ciinaboxes_dir, ciinabox_name
    config_tmpl = File.read("config/default_params.yml.example")
    services_tmpl = File.read("config/services.yml.example")
    ciinabox_tmpl = File.read("services/ciinabox.yml")
    default_config =  ERB.new(config_tmpl).result(binding)
    ciinabox_config =  ERB.new(ciinabox_tmpl).result(binding)
    File.open("#{ciinaboxes_dir}/#{ciinabox_name}/config/default_params.yml", 'w') { |f| f.write(default_config) }
    File.open("#{ciinaboxes_dir}/#{ciinabox_name}/config/services.yml", 'w') { |f| f.write(services_tmpl) }
    File.open("#{ciinaboxes_dir}/#{ciinabox_name}/services/ciinabox.yml", 'w') { |f| f.write(ciinabox_config) }
    display_active_ciinabox ciinaboxes_dir, ciinabox_name
  end

  desc('login into a azure ciinabox environment')
  task :login, :ciinabox do |t, args|
    check_active_ciinabox(config)
    ciinabox = args[:ciinabox] || ciinabox_name
    result = azure_login(config)
    if result
      azure_execute(config, ['config', 'mode', 'asm'])
      puts "activated ciinabox environment #{config['ciinabox_name']}"
      display_active_ciinabox ciinaboxes_dir, ciinabox
    else
      puts "fail to activate ciinabox environment"
      exit 1
    end
  end

  desc('current status of the active ciinabox')
  task :status do
    check_active_ciinabox(config)
    azure_execute(config, ['vm', 'show', "ciinabox-#{ciinabox_name}"])
    puts "deployed ciinabox services"
    puts "--------------------------"
    service_dir = "#{ciinaboxes_dir}/#{ciinabox_name}/services"
    services.each do |service|
      docker_compose(config, ["-f #{service_dir}/#{service}.yml", "-p ciinabox", "ps"])
    end
  end

  desc('creates the ciinabox environment')
  task :create do
    check_active_ciinabox(config)
    result = azure_execute(config,['vm', 'docker', 'create', "--location \"#{config['ciinabox_region']}\"", '--ssh 22', "--vm-size #{config['azure_vm_size']}", "ciinabox-#{ciinabox_name}", "\"#{config['azure_vm']}\"", "#{config['azure_username']}", "#{config['azure_password']}"])
    if !result
      puts "fail to activate ciinabox environment"
      exit 1
    end
    azure_execute(config, ['vm', 'endpoint', 'create', "ciinabox-#{ciinabox_name}", '80', '80'])
    azure_execute(config, ['vm', 'endpoint', 'create', "ciinabox-#{ciinabox_name}", '443', '443'])
    Rake::Task['ciinabox:deploy_core_services'].execute
  end

  desc('Deploys the core ciinabox services')
  task :deploy_core_services do
    ciinabox_tmpl = File.read("services/ciinabox.yml")
    ciinabox_config =  ERB.new(ciinabox_tmpl).result(binding)
    File.open("#{ciinaboxes_dir}/#{ciinabox_name}/services/ciinabox.yml", 'w') { |f| f.write(ciinabox_config) }
    docker_compose(config, ["-f #{ciinaboxes_dir}/#{ciinabox_name}/services/ciinabox.yml", "-p ciinabox", "up -d"])
  end

  desc('deploy current services to your ciinabox environment')
  task :deploy do
    check_active_ciinabox(config)
    render_services_templates config, services, ciinaboxes_dir, ciinabox_name
    service_dir = "#{ciinaboxes_dir}/#{ciinabox_name}/services"
    services.each do |service|
      docker_compose(config, ["-f #{service_dir}/#{service}.yml", "-p ciinabox", "up -d"])
    end
    Rake::Task['ciinabox:set_dns'].execute
  end

  desc('configured DNS for deployed services')
  task :set_dns do
    azure_execute(config,['config', 'mode', 'arm'])
    azure_execute(config,['provider', 'register', '--namespace Microsoft.Network'])
    services.each do |service|
      azure_execute(config, ['network','dns', 'record-set', 'create', "#{config['dns_resource_group']}", "#{config['dns_domain']}", "#{service}", 'CNAME'])
      azure_execute(config, ['network','dns', 'record-set', 'add-record', "#{config['dns_resource_group']}", "#{config['dns_domain']}", "#{service}", 'CNAME',  "-c ciinabox-#{ciinabox_name}.cloudapp.net"])
    end
    azure_execute(config,['config', 'mode', 'asm'])
  end

  desc('kill ciinabox services')
  task :kill do
    service_dir = "#{ciinaboxes_dir}/#{ciinabox_name}/services"
    services.each do |service|
      docker_compose(config, ["-f #{service_dir}/#{service}.yml", "-p ciinabox", "kill"])
    end
  end

  desc('delete/tears down the ciinabox environment')
  task :delete do
    check_active_ciinabox(config)
    result = azure_execute(config, ['vm', 'delete', '--quiet', '--blob-delete', "ciinabox-#{ciinabox_name}"])
    if !result
      puts "failed to delete ciinabox #{ciinabox_name}"
      exit 1
    end
  end

  def check_active_ciinabox(config)
    if(config.nil? || config['ciinabox_name'].nil?)
      puts "no active ciinabox please...run ./ciinabox active or ./ciinabox init"
      exit 1
    end
  end

  def azure_login(config)
    azure_execute(config, ['login'])
  end

  def azure_execute(config, cmd, output = nil)
    args = cmd.join(" ")
    if config['log_level'] == :debug
      puts "executing: azure #{args}"
    end
    if output.nil?
      result = execute("azure #{args}")
    else
      result = `azure #{args} > #{output}`
    end
    return result
  end

  def docker_compose(config, cmd)
    args = cmd.join(" ")
    if config['log_level'] == :debug
      puts "executing: docker-compose #{args}"
    end
    env = { "DOCKER_HOST" => "tcp://ciinabox-#{config['ciinabox_name']}.cloudapp.net:2376", "DOCKER_TLS_VERIFY" => "1"}
    result = execute("docker-compose #{args}", env)
  end

  def execute(cmd, env = {})
    require 'open3'
    Open3.popen2e(env, cmd) do |stdin, stdout_err, wait_thr|
      while line = stdout_err.gets
        puts line
      end
      return wait_thr.value
    end
  end

  def display_active_ciinabox(ciinaboxes_dir, ciinabox)
    puts "# Enable active ciinabox by executing or override ciinaboxes base directory:"
    puts "export CIINABOXES_DIR=\"#{ciinaboxes_dir}\""
    puts "export CIINABOX=\"#{ciinabox}\""
    puts "# or run"
    puts "# eval $(./ciinabox active[#{ciinabox}])"
  end

  def display_ip_address(config)
    ip_address = get_ip_address(config)
    if ip_address.nil?
      puts "Unable to get ECS cluster private ip"
    else
      puts "ECS cluster private ip:#{result}"
    end
  end

  def get_ciinabox_ip_address(config)
    return "127.0.0.1"
  end

  def get_input(prompt)
    puts prompt
    $stdin.gets.chomp
  end

  def render_services_templates(config, services, ciinaboxes_dir, ciinabox_name)
    services.each do |service|
      puts "generating #{service} service configuration"
      services_tmpl = File.read("services/#{service}.yml")
      service_config =  ERB.new(services_tmpl).result(binding)
      File.open("#{ciinaboxes_dir}/#{ciinabox_name}/services/#{service}.yml", 'w') { |f| f.write(service_config) }
    end
  end

  def create_dirs(dir, name)
    config_dirname = File.dirname("#{dir}/#{name}/config/ignore.txt")
    unless File.directory?(config_dirname)
      FileUtils.mkdir_p(config_dirname)
    end
    services_dirname = File.dirname("#{dir}/#{name}/services/ignore.txt")
    unless File.directory?(services_dirname)
      FileUtils.mkdir_p(services_dirname)
    end
    ssl_dirname = File.dirname("#{dir}/#{name}/ssl/ignore.txt")
    unless File.directory?(ssl_dirname)
      FileUtils.mkdir_p(ssl_dirname)
    end
    config_dirname
  end
end
