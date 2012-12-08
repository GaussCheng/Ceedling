require 'constants'
require 'mplabx_project_builder'

# generate mplabx project file
desc '''generate maplabx project file(template[app(default), static, share])'''
task :mplabx, [:project_name, :template] do |t, args|
  args.with_defaults(:project_name => File.basename(FileUtils.pwd), :template => MplabxProjectBuilder::TEMPLATE_APP)
  project_dir = args.project_name + '.X'
  if not @ceedling[:file_wrapper].exist?(project_dir)
    FileUtils.mkdir(project_dir)
  end
  @ceedling[MPLABXPROJECTBUILDER_SYM].name = args.project_name
  @ceedling[MPLABXPROJECTBUILDER_SYM].template = args.template
  @ceedling[MPLABXPROJECTBUILDER_SYM].project_path = Dir.new(project_dir)
  @ceedling[MPLABXPROJECTBUILDER_SYM].generate()
end