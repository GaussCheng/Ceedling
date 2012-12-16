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
  
  def generate_with_console(hconfig_tree)
    raise ArgumentError if hconfig_tree.class != Tree
    hconfig_utils = @ceedling[:hconfig_utils]
    config_define = hconfig_utils.hconfig_define
    hconfig_tree.each_children do |child|
      config = child.value
      if not hconfig_utils.config_en?(config)
        hconfig_utils.disable_configs_who_depends_on(child)
        next
      end
      print_config(config_define, config)
      begin
        anwser = ask_question_with_console("Do you want to enable config #{config[:name]}?", "YyNn")
        case anwser.downcase
        when "y" 
          puts @ceedling[:streaminator].green("#{config[:name]}: #{anwser}")
          hconfig_utils.set_config_enable(config, true)
          generate_with_console(child)
        when "n"
          puts @ceedling[:streaminator].yellow("#{config[:name]}: #{anwser}")
          hconfig_utils.set_config_enable(config, false)
          hconfig_utils.disable_configs_who_depends_on(child)
        end
      end while not ["y", "n"].include?(anwser)
    end
    # hconfig_tree.value[:configs].each_value do |config|
      # if not @ceedling[:hconfig_utils].config_depends_en?(config)
        # current_conf_hash[:"#{config[:name]}"] = false
        # next
      # end
      # print_config(current_conf_hash, config)
      # begin
        # anwser = ask_question_with_console("Do you want to enable config #{config[:name]}?", "YyNn")
        # puts "#{config[:name]}: #{anwser}"
        # case anwser.downcase
        # when "y" 
          # current_conf_hash[:"#{config[:name]}"] = true
          # hconfig_tree.each_children do |child|
            # generate_with_console(current_conf_hash, child)
          # end
        # when "n"
          # current_conf_hash[:"#{config[:name]}"] = false
        # end
      # end while not ["y", "n"].include?(anwser)
    # end
  end
  
  def print_config(current_config_hash, config)
    config_name = config[:name]
    is_config_en = current_config_hash[:"#{config_name}"]
    puts "----------------------------------------------------------------------"
    puts "Config Name: #{config_name}"
    puts "Depends On: #{config[:depends]}"
    puts "Description: #{config[:help]}"
    puts "Current defined ? #{is_config_en}"
  end
  
  def ask_question_with_console(question, hint)
    puts "#{question} [#{hint}]"
    ret = STDIN.gets
    return ret.chop
  end
  
  
end
