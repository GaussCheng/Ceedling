desc '''Generate hconfig configuration with console'''
task :console_hconfig do
  hconfig_define = {}
  @ceedling[:hconfig_utils].build_config_tree(hconfig_define)
  hconfig_tree = @ceedling[:hconfig_utils].hconfig_tree
  @ceedling[:hconfig_configurator].generate_with_console(hconfig_tree)
  puts "------------------------------------------------------------------------"
  hconfig_define.each do |key, value|
    if value == true
      puts "#{key}:" + @ceedling[:streaminator].green("#{value}")
    else
      puts "#{key}:" + @ceedling[:streaminator].yellow("#{value}")
    end
  end
  config_define_name = @ceedling[:configurator].project_config_hash[:used_hconfig]
  @ceedling[:yaml_wrapper].dump(config_define_name, hconfig_define)
end

desc '''Generate hconfig configuratin with tkgui'''
task :gui_hconfig do
  @ceedling[:hconfig_configurator].generate_with_gui()
end

desc '''Generate module dependency graph'''
task :mdgraph, [:graph_name] do |t, args|
  args.with_defaults(:graph_name => "graph")
  config_define_name = @ceedling[:configurator].project_config_hash[:used_hconfig]
  hconfig_define = @ceedling[:yaml_wrapper].load(config_define_name)
  puts @ceedling[:hconfig_utils].generate_module_dependency_graph(args[:graph_name], hconfig_define)
  
end
