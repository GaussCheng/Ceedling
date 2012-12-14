# This plugin help to generator a configuration file for a project that 
# use hconfig to maintain

require 'plugin'
require 'tree'

class HconfigConfigurator < Plugin
  
  def setup
    @result_list = []
    @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    # @environment = [ {:CEEDLING_USER_PROJECT_FILE => "builder.yml"} ]
    
    
  end
  
  def generate_with_console(current_conf_hash, hconfig_tree)
    raise ArgumentError if hconfig_tree.class != Tree
    hconfig_tree.value[:configs].each_value do |config|
      print_config(current_conf_hash, config)
    end
  end
  
  def print_config(current_config_hash, config)
    config_name = config[:name]
    is_config_en = current_config_hash[:"#{config_name}"]
    puts "Config Name: #{config_name}"
    puts "Depends On: #{config[:depends]}"
    puts "Description: #{config[:help]}"
    puts "Current defined ? #{is_config_en}"
    puts "----------------------------------------------------------------------"
  end
  
  
end
