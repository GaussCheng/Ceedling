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
    generate_configurations
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
      rebuild_project_tree(path.to_s.dup, logical_root)
    end
    out_file = File.open(File.join(project_path.path, "configurations.xml"), "w+")
    @configs.write(out_file, 2)
    out_file.close()
    # @project_dir_trees.each do |tree|
      # tree.each do |x|
        # puts x
      # end
      # puts "tree end"
    # end
    
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
  
  def rebuild_project_tree(path, root_element)
    path = FilePathUtils.standardize(path)
    dirs = path.split('/')
    trees = @project_dir_trees
    xml_element = root_element
    root = nil
    ele = nil
    #puts "path: #{path}"
    dirs.each do |dir|
      #puts "start , #{trees.empty?}, #{trees.class}, #{dir}"
      if trees.empty?
        if trees.class == Tree
          ele = xml_element.add_element("logicalFolder")
          set_logicalfolder_attributes(ele, dir, dir, true)
          root = trees << {dir => ele}
        else
          ele = xml_element.add_element("logicalFolder")
          set_logicalfolder_attributes(ele, dir, dir, true)
          root = Tree.new({dir => ele})
          trees.push(root)
        end
        trees = root
        xml_element = ele
      else
        is_in_tree = false
        if trees.class == Tree
          trees.children.each do |tree|
            if tree.value.has_key?(dir)
              trees = tree
              xml_element = tree.value[dir]
              is_in_tree = true
              break
            end
          end
          if not is_in_tree
            ele = xml_element.add_element("logicalFolder")
            set_logicalfolder_attributes(ele, dir, dir, true)
            root = root = trees << {dir => ele}
            trees = root
            xml_element = ele
          end
        else
          trees.each do |tree_root|
            if tree_root.value.has_key?(dir)
              trees = tree_root
              xml_element = tree_root.value[dir]
              is_in_tree = true
              break
            end
          end
          if not is_in_tree
            ele = xml_element.add_element("logicalFolder")
            set_logicalfolder_attributes(ele, dir, dir, true)
            root = Tree.new({dir => ele})
            trees.push(root)
            trees = root
            xml_element = ele
          end
        end
      end
    end
    #puts "rebuild finish"
  end
  
  def get_file_ext(file)
    file[/\.[^\.]+$/]
  end
  
end