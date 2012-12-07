require 'rubygems'
require 'rake'            # for ext() method
require 'securerandom'
require 'rexml/document'
require 'project_builder'
require 'find'

include REXML

class MplabxProjectBuilder < ProjectBuilder
  
  constructor :configurator_builder, :file_wrapper
  attr_reader :configs, :project
  attr_reader :uuid
  
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
  @@project_type_map = {ProjectBuilder::TEMPLATE_APP        => "0",
                        ProjectBuilder::TEMPLATE_STATIC_LIB => "1",
                        ProjectBuilder::TEMPLATE_SHARE_LIB  => "2"}

  def initialize(coding = "GBK")
    super(coding)
    @uuid = uuid 
    @configs = Document.new
    @project = Document.new
    @project << XMLDecl.new("1.0", "UTF-8")
    @configs << XMLDecl.new("1.0", "UTF-8")
  end
  
  def self.uuid
    ary = SecureRandom.random_bytes(16).unpack("NnnnnN")
    ary[2] = (ary[2] & 0x0fff) | 0x4000
    ary[3] = (ary[3] & 0x3fff) | 0x8000
    "%08x-%04x-%04x-%04x-%04x%08x" % ary
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
    
    # Object.const_get("COLLECTION_PATHS_SOURCE").each do |path|
      # puts path
    # end
    
    file_walk(".", ["./vendor/ceedling"], [".c", ".h"] )
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
    @@config_data[CONFIG_PRJ_TYPE] = @@project_type_map[template]
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
  
 def file_walk(path, exclude_paths, include_ext)
    Find.find(path) do |f|
      if FileTest.directory?(f)
        if exclude_paths.include?(f)
          Find.prune
        else
          next
        end
      end
      if include_ext.include?(get_file_ext(f))
        puts f
      end
    end
  end
  
  def get_file_ext(file)
    file[/\.[^\.]+$/]
  end
  
end