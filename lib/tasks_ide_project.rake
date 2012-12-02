require 'constants'
require 'fileutils'
require 'file_path_utils'
require 'mplabx_project'

# generate mplabx project file
desc "generate maplabx project file"
task :mplabx, [:project_name, :template] do |t, args|
  args.with_defaults(:project_name => File.basename(FileUtils.pwd), :template => IDEProject::TEMPLATE_APP)
  #puts @ceedling[:setupinator].config_hash
  project_dir = args.project_name + '.X'
  if not File.exist?(project_dir)
    FileUtils.mkdir(project_dir)
  end
  mplabx_project = MplabxProject.new(args.project_name, args.template, project_dir)
  mplabx_project.generate()
  puts mplabx_project.project
  puts mplabx_project.project_path.entries
  puts mplabx_project.name
  puts mplabx_project.template
  puts mplabx_project.uuid
end