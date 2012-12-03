require 'rexml/document'
require 'ide_project'

include REXML

class MplabxProject < IDEProject
  attr_reader :configs, :project
  
  CONFIG_CREATION_UUID  = "creation-uuid"
  CONFIG_NAME           = "name"
  CONFIG_PRJ_TYPE       = "make-project-type"
  CONFIG_ENCODING       = "sourceEncoding"
  @@config_data = {CONFIG_NAME          => "",
                   CONFIG_CREATION_UUID => "",
                   CONFIG_PRJ_TYPE      => "0",
                   "c-extensions"       => "c",
                   "cpp-extensions"     => "",
                   "header-extensions"  => "h",
                   CONFIG_ENCODING      => "GBK",
                   "make-dep-projects"  => ""}

  def initialize(name, template, project_path, coding = "GBK")
    super(name, template, project_path, coding)
    @configs = Document.new
    @project = Document.new
    @project << XMLDecl.new("1.0", "UTF-8")
    @configs << XMLDecl.new("1.0", "UTF-8")
  end
  
  def generate
    generate_project()
  end
  
  private
  
  def generate_project
    root = @project.add_element("project")
    project_type(root)
    project_configuration(root)
    out_file = File.open(File.join(project_path.path, "project.xml"), "w+")
    @project.write(out_file, 2)
    out_file.close()
  end
  
  def generate_configurations
    root = @configs.add_element("configurationDescriptor")
    logical_root = root.add_element("logicalFolder")
  end
  
  def project_type(root)
    type = root.add_element("type")
    type.add_text("com.microchip.mplab.nbide.embedded.makeproject")
  end
  
  def project_configuration(root)
    configuration = root.add_element("configuration")
    data = configuration.add_element("data")
    data.add_attribute("xmlns", "http://www.netbeans.org/ns/make-project/1")
    @@config_data[CONFIG_PRJ_TYPE] = template
    @@config_data[CONFIG_NAME] = name
    @@config_data[CONFIG_CREATION_UUID] = uuid
    @@config_data[CONFIG_ENCODING] = coding
    
    @@config_data.each do |key, value|
      elem = data.add_element("#{key}")
      if not "#{value}".empty?
        elem.add_text("#{value}")
      end
    end
  end
  
  
end