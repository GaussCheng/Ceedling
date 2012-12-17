# This plugin help to generator a configuration file for a project that 
# use hconfig to maintain

require 'plugin'
require 'tree'

class HconfigConfigurator < Plugin
  
  def setup
    @result_list = []
    @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    # @environment = [ {:CEEDLING_USER_PROJECT_FILE => "builder.yml"} ]
    
    
  end
  
  def generate_with_console(hconfig_tree)
    raise ArgumentError if hconfig_tree.class != Tree
    hconfig_utils = @ceedling[:hconfig_utils]
    hconfig_tree.each_children do |child|
      config = child.value
      if not hconfig_utils.config_en?(config)
        hconfig_utils.disable_configs_who_depends_on(config[:name])
        next
      end
      print_config(config)
      begin
        anwser = ask_question_with_console("Do you want to enable config #{config[:name]}?", "YyNn")
        case anwser.downcase
        when "y" 
          puts @ceedling[:streaminator].green("#{config[:name]}: #{anwser}")
          hconfig_utils.set_config_enable(config, true)
          generate_with_console(child)
        when "n"
          puts @ceedling[:streaminator].yellow("#{config[:name]}: #{anwser}")
          hconfig_utils.set_config_enable(config, false)
          hconfig_utils.disable_configs_who_depends_on(config[:name])
        end
      end while not ["y", "n"].include?(anwser)
    end
  end
  
  def generate_with_gui(hconfig_tree)
    require 'Qt'
    app = Qt::Application.new(ARGV)
    main_frame = MainFrame.new
    main_frame.hconfig_utils = @ceedling[:hconfig_utils]
    main_frame.load_configs(@ceedling[:hconfig_utils].hconfig_tree, nil)
    main_frame.expand_all
    main_frame.resize_column_to_contents(0)
    # str = Time.now.strftime("Today is %B %d, %Y")
    # label = Qt::Label.new(str)
    # label.show
    main_frame.show
    app.exec    
  end
  
  def print_config(config)
    config_name = config[:name]
    #is_config_en = current_config_hash[:"#{config_name}"]
    puts "----------------------------------------------------------------------"
    puts "Config Name: #{config_name}"
    puts "Depends On: #{config[:depends]}"
    puts "Description: #{config[:help]}"
    #puts "Current defined ? #{is_config_en}"
  end
  
  def ask_question_with_console(question, hint)
    print "#{question} [#{hint}]"
    ret = STDIN.gets
    return ret.chop
  end
  
end

require 'Qt'
class MainFrame < Qt::MainWindow
  slots 'expand_all()', 'collapse_all()', 'on_config_define_changed(QTreeWidgetItem* item, int column)'
  attr_accessor :hconfig_utils
  def initialize(parent = nil)
    super(parent)
    resize(1024, 800)
    setWindowTitle("Hconfig")
    @hconfig_utils = nil
    @menu_bar = Qt::MenuBar.new(self)
    @file_menu = Qt::Menu.new("&File")
    @open_action = @file_menu.addAction("&Open")
    @save_action = @file_menu.addAction("&Save")
    @tool_menu = Qt::Menu.new("&Tool")
    @enable_all_action = @tool_menu.addAction("&Enable all")
    @diable_all_action = @tool_menu.addAction("&Disable all")
    @menu_bar.addMenu(@file_menu)
    @menu_bar.addMenu(@tool_menu)
    @tool_bar = Qt::ToolBar.new
    @collapse_action = @tool_bar.addAction("Collapse")
    @expand_action = @tool_bar.addAction("Expand")
    setMenuBar(@menu_bar)
    addToolBar(@tool_bar)
    
    @configs_view = Qt::DockWidget.new
    @configs_widget = Qt::Widget.new(@configs_view)
    @configs_view.setFloating(false)
    @configs_view.setFeatures(Qt::DockWidget::NoDockWidgetFeatures)
    @configs_view.setWidget(@configs_widget)
    @descr_view = Qt::DockWidget.new
    @descr_widget = Qt::Widget.new(@descr_view)
    @descr_view.setFloating(false)
    @descr_view.setFeatures(Qt::DockWidget::NoDockWidgetFeatures)
    @descr_view.setWidget(@descr_widget)
    
    addDockWidget(Qt::LeftDockWidgetArea, @configs_view)
    addDockWidget(Qt::RightDockWidgetArea, @descr_view)
    @configs_view_layout = Qt::VBoxLayout.new(@configs_widget)
    @descr_view_layout = Qt::VBoxLayout.new(@descr_widget)
    @configs_tree_widget = Qt::TreeWidget.new
    @descr_text_browser = Qt::TextBrowser.new
    @configs_view_layout.addWidget(@configs_tree_widget)
    @descr_view_layout.addWidget(@descr_text_browser)
    @configs_widget.setLayout(@configs_view_layout)
    @descr_widget.setLayout(@descr_view_layout)
    
    @configs_tree_widget.setHeaderLabels(["Id", "Name"])
    
    connect(@expand_action, SIGNAL('triggered()'), self, SLOT('expand_all()'))
    connect(@collapse_action, SIGNAL('triggered()'), self, SLOT('collapse_all()'))
  end
  
  def resize_column_to_contents(col)
    @configs_tree_widget.resizeColumnToContents(col)
  end
  
  def expand_all
    @configs_tree_widget.expandAll
  end
  
  def collapse_all
    @configs_tree_widget.collapseAll
  end
  
  def on_config_define_changed(tree_item, col)
    
  end
  
  def load_configs(hconfig_tree, parent_tree_widget_item)
    if parent_tree_widget_item.nil?
      parent_tree_widget_item = @configs_tree_widget
    end
    hconfig_tree.each_children do |child|
      config = child.value
      tree_item = Qt::TreeWidgetItem.new(parent_tree_widget_item, [config[:name], config[:prompt]])
      if @hconfig_utils.config_en?(config)
        tree_item.setCheckState(0, Qt::Checked)
      else
        tree_item.setCheckState(0, Qt::UnChecked)
      end
      @configs_tree_widget.addTopLevelItem(tree_item)
      load_configs(child, tree_item)
    end
  end
end
