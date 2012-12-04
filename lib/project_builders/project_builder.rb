# The base class of IDE project files
class ProjectBuilder
  TEMPLATE_APP          = "app"
  TEMPLATE_STATIC_LIB   = "static"
  TEMPLATE_SHARE_LIB    = "share"
  
  attr_accessor :name, :coding, :template, :project_path, :ceedling
  
  def initialize(coding = "GBK")
    @name = ""
    @coding = coding
    @template = TEMPLATE_APP
    @project_path= NIL
    @ceedling = {}
  end
  
  def generate
    ""
  end
end