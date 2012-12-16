# This file contain functions to work for hconfig.yml

require 'rgl/adjacency'
require 'tree'
require 'file_path_utils'


class HconfigUtils
  
  attr_accessor :hconfig_tree, :hconfig_define
  constructor(:configurator, :yaml_wrapper, :file_wrapper, :streaminator)
  
  def setup
    @hconfig_tree = Tree.new("root")
    @hconfig_define = {}
    @hconfig_depends_graph = RGL::DirectedAdjacencyGraph.new
  end
  
  def build_config_tree
    build_config_define
    hconfig_name = @configurator.project_config_hash[:hconfig_name]
    if not File.exist?(hconfig_name)
      @streaminator.stdout_puts "Root config file #{hconfig_name} not found!"
      return
    end
    configs = @yaml_wrapper.load(hconfig_name)
    configs[:configs].each do |config|
      hconfig_tree_node = @hconfig_tree << config[:config]
      parse_hconfig(hconfig_tree_node, '.', hconfig_name)
    end
    
    require 'rgl/dot'
    @hconfig_depends_graph.write_to_graphic_file()
    `dot -Tpng graph.dot -o graph.png`
  end
  
  def build_config_define
    config_define_name = @configurator.project_config_hash[:used_hconfig]
    if not File.exist?(config_define_name)
      @streaminator.stdout_puts "Used config #{config_define_name} is not found!"
      return
    end
    @hconfig_define = @yaml_wrapper.load(config_define_name)
  end
  
  def collect_defined_source
    all_source = @file_wrapper.instantiate_file_list
    # @hconfig_tree.value[:configs].each do |config_hash|
      # parse_config_source(config_hash[:config], all_source)
    # end
    collect_defined_source_impl(@hconfig_tree, all_source)
    return all_source
  end
  
  def config_depends(config_hash)
    return [] if config_hash[:depends].nil?
    depends = config_hash[:depends].partition(',')
    depends.delete_if { |str| str.empty? }
    return depends
  end
  
  def config_depends_en?(config_hash)
    depends = config_depends(config_hash)
    depends.each do |config|
      if @hconfig_define[:"#{config}"] == false
        return false
      end
    end
    return true
  end
  
  def config_en?(config_hash)
    return check_depends_is_en_deeply(config_hash[:name])
  end
  
  def set_config_enable(config_hash, is_enable)
    @hconfig_define[:"#{config_hash[:name]}"] = is_enable
  end
  
  def disable_configs_who_depends_on(hconfig_node)
    hconfig_node.each do |config|
      set_config_enable(config, false)
    end
  end
  
  private 
  
  def check_depends_is_en_deeply(vertex)
    return false if @hconfig_define[:"#{vertex}"] == false
    if @hconfig_depends_graph.has_vertex?(vertex)
      if not @hconfig_depends_graph.cycles_with_vertex(vertex).empty?
        puts @streaminator.red("Found cycle depends of #{vertex}!")
        return false
      end 
      @hconfig_depends_graph.each_adjacent(vertex) do |v|
        check_depends_is_en_deeply(v)  
      end
    end
    return true
  end
  
  def collect_defined_source_impl(hconfig_node, file_list)
    raise ArgumentError if file_list.class != FileList
    raise ArgumentError if hconfig_node.class != Tree
    hconfig_node.each_children do |child|
      if parse_config_source(child.value, file_list)
        collect_defined_source_impl(child, file_list)
      end
    end
  end
  
  def parse_config_source(config_hash, file_list)
    raise ArgumentError if file_list.class != FileList
    if config_en?(config_hash)
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
    if not config_en?(parent_config.value)
      return
    end
    @hconfig_depends_graph.add_vertex(parent_config.value[:name])
    config_depends(parent_config.value).each do |depend_config_name|
      @hconfig_depends_graph.add_edge(depend_config_name, parent_config.value[:name])
    end
    sources = parent_config.value[:source]
    hconfig_dir = nil
    hconfig = nil
    sources.each_index do |i|
      hconfig_dir = File.join(config_path, sources.at(i))
        hconfig = File.join(hconfig_dir, hconfig_name)
        sources[i] = FilePathUtils.standardize(File.join(config_path, sources.at(i)))
        if File.exist?(hconfig)
          print "Loading #{hconfig}..."
          configs = @yaml_wrapper.load(hconfig)
          puts " [ " + @streaminator.green('DONE') + " ]"
          configs[:configs].each do |config|
            child = parent_config << config[:config]
            @hconfig_depends_graph.add_edge(child.value[:name], parent_config.value[:name])
            parse_hconfig(child, hconfig_dir, hconfig_name)
          end
        end
    end
  end
  
end