# This file contain functions to work for hconfig.yml

require 'tree'
require 'file_path_utils'


class HconfigUtils
  
  attr_accessor :hconfig_tree, :hconfig_define
  constructor(:configurator, :yaml_wrapper, :file_wrapper)
  
  def setup
    @hconfig_tree = Tree.new(nil)
    @hconfig_define = {}
  end
  
  def build_config_tree
    hconfig_name = @configurator.project_config_hash[:hconfig_name]
    if not File.exist?(hconfig_name)
      puts "Root config file #{hconfig_name} not found!"
      return
    end
    @hconfig_tree.value = @yaml_wrapper.load(hconfig_name)
    parse_hconfig(@hconfig_tree, '.', hconfig_name)
  end
  
  def build_config_define
    config_define_name = @configurator.project_config_hash[:used_hconfig]
    if not File.exist?(config_define_name)
      puts "Used config #{config_define_name} is not found!"
      return
    end
    @hconfig_define = @yaml_wrapper.load(config_define_name)
  end
  
  def collect_defined_source
    all_source = @file_wrapper.instantiate_file_list
    @hconfig_tree.value[:configs].each_value do |config|
      parse_config_source(config, all_source)
    end
    collect_defined_source_impl(@hconfig_tree, all_source)
    return all_source
  end
  
  private 
  
  def collect_defined_source_impl(hconfig_node, file_list)
    raise ArgumentError if file_list.class != FileList
    raise ArgumentError if hconfig_node.class != Tree
    hconfig_node.each_children do |child|
      child.value[:configs].each_value do |config|
        if parse_config_source(config, file_list)
          collect_defined_source_impl(child, file_list)
        end
      end
    end
  end
  
  def parse_config_source(config_hash, file_list)
    raise ArgumentError if file_list.class != FileList
    if @hconfig_define[:"#{config_hash[:name]}"] == true
      all_source = @file_wrapper.instantiate_file_list
      config_hash[:source].each do |path|
        all_source.include(path)
      end
      all_source.delete_if { |path| not File.exist?(path) or File.directory?(path) }
      file_list.include(all_source)
      return true      
    end
    return false
  end
  
  def parse_hconfig(parent_config, config_path, hconfig_name)
    sources  = parent_config.value[:configs][:config][:source]
    hconfig_dir = nil
    hconfig = nil
    sources.each_index do |i|
      hconfig_dir = File.join(config_path, sources.at(i))
      hconfig = File.join(hconfig_dir, hconfig_name)
      sources[i] = FilePathUtils.standardize(File.join(config_path, sources.at(i)))
      if File.exist?(hconfig)
        child = parent_config << @yaml_wrapper.load(hconfig)
        parse_hconfig(child, hconfig_dir, hconfig_name)
      end
    end
  end
  
end
