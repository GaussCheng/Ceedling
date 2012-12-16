
desc '''generate hconfig configuration with console'''
task :console_hconfig do
  @ceedling[:hconfig_utils].build_config_tree
  hconfig_tree = @ceedling[:hconfig_utils].hconfig_tree
  hconfig_define = @ceedling[:hconfig_utils].hconfig_define
  @ceedling[:hconfig_configurator].generate_with_console(hconfig_tree)
  puts "------------------------------------------------------------------------"
  hconfig_define.each do |key, value|
    if value == true
      puts "#{key}:" + @ceedling[:streaminator].green("#{value}")
    else
      puts "#{key}:" + @ceedling[:streaminator].yellow("#{value}")
    end
  end
end