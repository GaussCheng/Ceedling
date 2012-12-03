# The base class of IDE project files
class ProjectBuilder
  TEMPLATE_APP          = "app"
  TEMPLATE_STATIC_LIB   = "static"
  TEMPLATE_SHARE_LIB    = "share"
  
  attr_accessor :name, :coding, :template, :project_path
  
  def initialize(name, template, project_path, coding = "GBK")
    @name = name
    @coding = coding
    @template = TEMPLATE_APP
    @project_path= Dir.new(project_path)
  end
  
  def generate
    ""
  end
end