require 'rubygems'
require 'rake'            # for ext() method
require 'securerandom'
require 'rexml/document'
require 'find'
require 'plugin'
require 'tree'

include REXML

MPLABXPROJECTBUILDER_ROOT_NAME         = 'mplabx_project_builder'
MPLABXPROJECTBUILDER_TASK_ROOT         = MPLABXPROJECTBUILDER_ROOT_NAME + ':'
MPLABXPROJECTBUILDER_SYM               = MPLABXPROJECTBUILDER_ROOT_NAME.to_sym

class MplabxProjectBuilder < Plugin
  
  TEMPLATE_APP          = "app" 
  TEMPLATE_STATIC_LIB   = "static"
  TEMPLATE_SHARE_LIB    = "share"
  
  attr_reader :configs, :project
  attr_reader :uuid
  attr_accessor :name, :coding, :template, :project_path, :ceedling
  
  
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
  @@project_type_map = {TEMPLATE_APP        => "0",
                        TEMPLATE_STATIC_LIB => "1",
                        TEMPLATE_SHARE_LIB  => "2"}

  def setup
    @result_list = []
    # @environment = [ {:CEEDLING_USER_PROJECT_FILE => "builder.yml"} ]
    @name = ""
    @coding = coding
    @template = TEMPLATE_APP
    @coding = "GBK"
    @project_path= NIL
    @uuid = uuid 
    @configs = Document.new
    @project = Document.new
    @project << XMLDecl.new("1.0", "UTF-8")
    @configs << XMLDecl.new("1.0", "UTF-8")
    @project_dir_trees = []
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
    #walk(".", ["./vendor/ceedling"], [".c", ".h"])
    generate_configurations
    
  end
  
  def generate_configurations
    root = @configs.add_element("configurationDescriptor")
    logical_root = root.add_element("logicalFolder")
    set_logicalfolder_attributes(logical_root, "root", "root", "true")
    
    
    # logical_head = logical_root.add_element("logicalFolder")
    # set_logicalfolder_attributes(logical_head, "HeaderFiles", "Header Files", "true")
    
    logical_linker = logical_root.add_element("logicalFolder")
    set_logicalfolder_attributes(logical_linker, "LinkerScript", "Liker Script", "true")
    
    @ceedling[:file_system_utils].collect_paths(@ceedling[:setupinator].config_hash[:code_path][:source]).each do |path|
      rebuild_project_tree(path, logical_root)
    end
    puts @project_dir_tree.keys
    
    # logical_source = logical_root.add_element("logicalFolder")
    # set_logicalfolder_attributes(logical_source, "SourceFiles", "Source Files", "true")
    
    # logical_externals= logical_root.add_element("logicalFolder")
    # set_logicalfolder_attributes(logical_externals, "ExternalFiles", "Important Files", "false")
    # temp_item = logical_externals.add_element("itemPath")
    # temp_item.add_text("Makefile")
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
  
  def set_logicalfolder_attributes(element,name, display_name, project_files)
    element.add_attributes("name" => name, "displayName" => display_name, "projectFiles" => project_files)
  end
  
  def path_compose(path)
    path = FilePathUtils.standardize(path)
    dirs = path.split('/')
    ret = []
    tmp = ""
    dirs.each do | dir|
      tmp += dir + "/"
      ret.push(tmp)
    end
    return ret
  end
  
  def rebuild_project_tree(path, root_elment)
    path = FilePathUtils.standardize(path)
    dirs = path.split('/')
    @project_dir_trees.each do |tree|
      # if tree.value 
    end
    # file_ext = nil
    # Find.find(path) do |file|
      # if FileTest.directory?(file)
        # if exclude_paths.include?(file)
          # Find.prune       # Don't look any further into this directory.
        # else
          # next
        # end
      # end
      # file_ext = get_file_ext(file)
      # if include_ext.include?(file_ext)
#         
      # end
    # end
  end
  
  def get_file_ext(file)
    file[/\.[^\.]+$/]
  end
  
end