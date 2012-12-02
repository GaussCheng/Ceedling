require 'securerandom'

# The base class of IDE project files
class IDEProject
  TEMPLATE_APP          = 0
  TEMPLATE_STATIC_LIB   = 1
  TEMPLATE_SHARE_LIB    = 2
  
  attr_accessor :name, :coding, :template, :project_path
  attr_reader :uuid
  
  def initialize(name, template, project_path, coding = "GBK")
    @name = name
    @coding = coding
    @uuid = SecureRandom.uuid
    @template = TEMPLATE_APP
    @project_path= Dir.new(project_path)
  end
  
  def generate
    ""
  end
end