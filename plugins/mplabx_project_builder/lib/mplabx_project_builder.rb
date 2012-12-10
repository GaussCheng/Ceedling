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
MPLABXPROJECTBUILDER_CONF              = 'mplabx_builder.yml'

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
  @@project_type_map = {TEMPLATE_APP        => "2",
                        TEMPLATE_STATIC_LIB => "1",
                        TEMPLATE_SHARE_LIB  => "2"}

  def setup
    @result_list = []
    @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    # @environment = [ {:CEEDLING_USER_PROJECT_FILE => "builder.yml"} ]
    @name = ""
    @coding = coding
    @template = TEMPLATE_APP
    @coding = "GBK"
    @project_path= NIL
    @uuid = MplabxProjectBuilder.uuid 
    @configs = Document.new
    @project = Document.new
    @project << XMLDecl.new("1.0", "UTF-8")
    @configs << XMLDecl.new("1.0", "UTF-8")
    @project_dir_trees = [] 
    @config_hash = @ceedling[:setupinator].config_hash
  end
  
  def self.uuid
    # return "cab8a1af-6994-43fa-a4ff-c4f777e19fae"
    ary = SecureRandom.random_bytes(16).unpack("NnnnnN")
    ary[2] = (ary[2] & 0x0fff) | 0x4000
    ary[3] = (ary[3] & 0x3fff) | 0x8000
    "%08x-%04x-%04x-%04x-%04x%08x" % ary
  end
  
  def generate
    @ceedling[:file_wrapper].cp(File.join(@plugin_root, 'assets/Makefile'), 
                                File.join(project_path.path, "Makefile"))
    @ceedling[:file_wrapper].cp(File.join(@plugin_root, "assets/#{MPLABXPROJECTBUILDER_CONF}"), 
                                File.join(project_path.path, MPLABXPROJECTBUILDER_CONF))
    @config_hash = @ceedling[:yaml_wrapper].load(File.join(project_path.path, MPLABXPROJECTBUILDER_CONF))
    
    generate_project
    generate_configurations
  end
  
  private
  
  def generate_project
    root = @project.add_element("project")
    root.add_attribute("xmlns", "http://www.netbeans.org/ns/project/1")
    project_type(root)
    project_configuration(root)
    out_file = File.open(File.join(project_path.path + "/nbproject/", "project.xml"), "w+")
    @project.write(out_file)
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
    
    paths = @ceedling[:file_system_utils].collect_paths(@config_hash[:code_path][:source] + 
                                                        @config_hash[:code_path][:header])
    extensions = @ceedling[:file_system_utils].collect_paths(@config_hash[:file_extension][:source]) +
                 @ceedling[:file_system_utils].collect_paths(@config_hash[:file_extension][:header])
    code_files = collect_code_files(paths, extensions)
    code_files.each do |code_file|
      rebuild_project_tree(code_file.to_s.dup, logical_root)      
    end
    logical_externals= logical_root.add_element("logicalFolder")
    set_logicalfolder_attributes(logical_externals, "ExternalFiles", "Important Files", "false")
    temp_item = logical_externals.add_element("itemPath")
    temp_item.add_text("Makefile")
    
    temp_element = root.add_element("projectmakefile")
    temp_element.add_text("Makefile")
    confs =  root.add_element("confs")
    conf(confs, "default")
    out_file = File.open(File.join(project_path.path + "/nbproject/", "configurations.xml"), "w+")
    @configs.write(out_file)
    out_file.close()
    # @project_dir_trees.each do |tree|
      # tree.each do |x|
        # puts x
      # end
      # puts "tree end"
    # end
    
    # logical_source = logical_root.add_element("logicalFolder")
    # set_logicalfolder_attributes(logical_source, "SourceFiles", "Source Files", "true")
    
  end
  
  def project_type(root)
    type = root.add_element("type")
    type.add_text("com.microchip.mplab.nbide.embedded.makeproject")
  end
  
  def project_configuration(root)
    configuration = root.add_element("configuration")
    data = configuration.add_element("data")
    data.add_attribute("xmlns", "http://www.netbeans.org/ns/make-project/1")
    @@config_data[CONFIG_PRJ_TYPE] = @@project_type_map[@template]
    @@config_data[CONFIG_NAME] = @name
    @@config_data[CONFIG_CREATION_UUID] = @uuid
    @@config_data[CONFIG_ENCODING] = @coding
    @@config_data.each do |key, value|
      elem = data.add_element("#{key}")
      if not "#{value}".empty?
        elem.add_text("#{value}")
      end
    end
  end
  
  def conf(confs, name)
    conf = confs.add_element("conf")
    conf.add_attributes("name"=>name, "type"=>@@project_type_map[@template])
    conf_tools_set(conf)
    conf_compile_type(conf)
    conf_make_customization_type(conf)
    cc_properties(conf)
    as_properties(conf)
    ld_properties(conf)
    cpp_properties(conf)
    global_properties(conf)
  end
  
  def conf_tools_set(conf)
    tools_set = conf.add_element("toolsSet")
    temp_element = tools_set.add_element("developmentServer")
    temp_element.add_text("localhost")
    temp_element = tools_set.add_element("targetDevice")
    temp_element.add_text(@config_hash[:tools_set][:target_device])
    tools_set.add_element("targetHeader")
    tools_set.add_element("targetPluginBoard")
    temp_element = tools_set.add_element("platformTool")
    temp_element.add_text(@config_hash[:tools_set][:platform_tool])
    temp_element = tools_set.add_element("languageToolchain")
    temp_element.add_text(@config_hash[:tools_set][:language_tool_chain])
    temp_element = tools_set.add_element("languageToolchainVersion")
    temp_element.add_text(@config_hash[:tools_set][:language_tool_chain_version])
    temp_element = tools_set.add_element("platform")
    temp_element.add_text("2")
  end
  
  def conf_compile_type(conf)
    compile_type = conf.add_element("compileType")
    temp_element = compile_type.add_element("linkerTool")
    temp_element = temp_element.add_element("linkerLibItems")
    temp_element = conf.add_element("loading")
    temp = temp_element.add_element("useAlternateLoadableFile")
    temp.add_text("false")
    temp_element.add_element("alternateLoadableFile")
  end
  
  def conf_make_customization_type(conf)
    make_custom = conf.add_element("makeCustomizationType")
    temp_element = make_custom.add_element("makeCustomizationPreStepEnabled")
    temp_element.add_text("false")
    temp_element = make_custom.add_element("makeCustomizationPreStep")
    temp_element = make_custom.add_element("makeCustomizationPostStepEnabled")
    temp_element.add_text("false")
    temp_element = make_custom.add_element("makeCustomizationPostStep")
    temp_element = make_custom.add_element("makeCustomizationPutChecksumInUserID")
    temp_element.add_text("false")
    temp_element = make_custom.add_element("makeCustomizationEnableLongLines")
    temp_element.add_text("false")
    temp_element = make_custom.add_element("makeCustomizationNormalizeHexFile")
    temp_element.add_text("false")
  end
  
  def cc_properties(conf)
    @config_hash[:cc_properties][:extra_include_directories] = "../" + 
        @ceedling[:file_system_utils].collect_paths(@config_hash[:code_path][:header]).join(";../")
    properties = conf.add_element("C32")
    properties_element_helper(properties, @config_hash[:cc_properties])
  end
  
  def as_properties(conf)
    properties = conf.add_element("C32-AS")
    properties_element_helper(properties, @config_hash[:as_properties])
  end
  
  def ld_properties(conf)
    properties = conf.add_element("C32-LD")
    properties_element_helper(properties, @config_hash[:ld_properties])
  end
  
  def cpp_properties(conf)
    conf.add_element("C32CPP")
  end
  
  def global_properties(conf)
    properties = conf.add_element("C32Global")
    properties_element_helper(properties, @config_hash[:global_properties])
  end
  
  def properties_element_helper(element, config_hash)
    config_hash.each do |key, value|
      # puts "key:#{key} value:#{value}"
      element.add_element("property", {"key" => key.to_s.gsub("_", "-"), "value"=>value})
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
    dirs.pop
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
    ele = xml_element.add_element("itemPath")
    ele.add_text("../#{path}")
    
    #puts "rebuild finish"
  end
  
  def get_file_ext(file)
    file[/\.[^\.]+$/]
  end
  
  def collect_code_files(paths, extensions)
    all_source = @ceedling[:file_wrapper].instantiate_file_list
    paths.each do |path|
      if File.exists?(path) and not File.directory?(path)
        all_source.include( path )
      else
        extensions.each do |extension|
          all_source.include( File.join(path, "*#{extension}") )
        end
      end
    end
    return all_source
  end
  
end