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
    @hconfig_depends_reverse_graph = nil
    @hconfig_name_to_hconfig_tree_map = {}
  end
  
  def build_config_tree(hconfig_define_hash)
    #build_config_define
    @hconfig_define = hconfig_define_hash
    @hconfig_tree = Tree.new("root")
    hconfig_name = @configurator.project_config_hash[:hconfig_name]
    if hconfig_name.nil? or not File.exist?(hconfig_name) 
      @streaminator.stdout_puts @streaminator.red("Root config file #{hconfig_name} not found!")
      return
    end
    configs = @yaml_wrapper.load(hconfig_name)
    configs[:configs].each do |config|
      hconfig_tree_node = @hconfig_tree << config[:config]
      parse_hconfig(hconfig_tree_node, '.', hconfig_name)
    end
    
    @hconfig_depends_reverse_graph = @hconfig_depends_graph.reverse
  end
  
  # def build_config_define
    # config_define_name = @configurator.project_config_hash[:used_hconfig]
    # if not File.exist?(config_define_name)
      # @streaminator.stdout_puts "Used config #{config_define_name} is not found!"
      # return
    # end
    # @hconfig_define = @yaml_wrapper.load(config_define_name)
  # end
  
  def collect_defined_source
    all_source = @file_wrapper.instantiate_file_list
    collect_defined_source_impl(@hconfig_tree, all_source)
    return all_source
  end
  
  def config_depends(config_hash)
    return [] if config_hash[:depends].nil?
    depends = config_hash[:depends].partition(',')
    depends.delete_if { |str| str.empty? or str.nil?}
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
  
  def who_depends_on(config_hash)
    ret = []
    if @hconfig_depends_reverse_graph.has_vertex?(config_hash[:name])
      @hconfig_depends_reverse_graph.each_adjacent(config_hash[:name]) do |v|
        ret.push(@hconfig_name_to_hconfig_tree_map[v].value)
      end
    end
    ret.delete_if { |config| config.empty? or config.nil?}
    return ret
  end
  
  def set_config_enable(config_hash, is_enable)
    @hconfig_define[:"#{config_hash[:name]}"] = is_enable
  end
  
  def disable_configs_who_depends_on(config_name)
    @hconfig_define[:"#{config_name}"] = false
    if @hconfig_depends_reverse_graph.has_vertex?(config_name)
      if not @hconfig_depends_reverse_graph.cycles_with_vertex(config_name).empty?
        puts @streaminator.red("Found cycle depends of #{config_name}!")
        return
      end 
      @hconfig_depends_reverse_graph.each_adjacent(config_name) do |v|
        disable_configs_who_depends_on(v)  
      end
    end
  end
  
  def generate_module_dependency_graph(name, hconfig_define)
    require 'rgl/dot'
    build_config_tree(hconfig_define)
    @hconfig_depends_graph.write_to_graphic_file()
  end
  
  private 
  
  def check_depends_is_en_deeply(vertex)
    # return true if not @hconfig_define.has_key?(vertex)
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
      @hconfig_depends_graph.add_edge(parent_config.value[:name], depend_config_name)
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
            @hconfig_name_to_hconfig_tree_map[child.value[:name]] = child
            @hconfig_depends_graph.add_edge(child.value[:name], parent_config.value[:name])
            parse_hconfig(child, hconfig_dir, hconfig_name)
          end
        end
    end
  end
  
end
