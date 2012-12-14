
desc '''generate hconfig configuration with console'''
task :console_hconfig do
  @ceedling[:hconfig_utils].build_config_tree
  @ceedling[:hconfig_utils].build_config_define
  hconfig_tree = @ceedling[:hconfig_utils].hconfig_tree
  hconfig_define = @ceedling[:hconfig_utils].hconfig_define
  @ceedling[:hconfig_configurator].generate_with_console(hconfig_define, hconfig_tree)
end