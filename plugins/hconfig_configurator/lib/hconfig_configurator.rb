# This plugin help to generator a configuration file for a project that 
# use hconfig to maintain

require 'plugin'
require 'tree'
require 'yaml_wrapper'

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
  
  def generate_with_gui()
    require 'Qt4'
    app = Qt::Application.new(ARGV)
    main_frame = MainFrame.new
    hconfig_utils = @ceedling[:hconfig_utils]
    main_frame.hconfig_utils = hconfig_utils
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

require 'Qt4'
class MainFrame < Qt::MainWindow
  slots 'expand_all()', 
        'collapse_all()', 
        'enable_all()', 
        'disable_all()', 
        'on_config_define_changed(QTreeWidgetItem*, int)',
        'open_config_file()',
        'save_config_file()',
        'on_item_activated(QTreeWidgetItem*, int)',
        'on_anchor_clicked(const QUrl&)'
  attr_accessor :hconfig_utils
  def initialize(parent = nil)
    super(parent)
    resize(1024, 800)
    setWindowTitle("Hconfig")
    @hconfig_utils = nil
    @config_define = {}
    @hconfig_to_tree_item_map = {}
    @tree_item_to_hconfig_map = {}
    @config_name_to_hconfig_map = {}
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
    @descr_text_edit = Qt::TextBrowser.new
    @configs_view_layout.addWidget(@configs_tree_widget)
    @descr_view_layout.addWidget(@descr_text_edit)
    @configs_widget.setLayout(@configs_view_layout)
    @descr_widget.setLayout(@descr_view_layout)
    
    @configs_tree_widget.setHeaderLabels(["Id", "Name"])
    
    connect(@expand_action, SIGNAL('triggered()'), self, SLOT('expand_all()'))
    connect(@collapse_action, SIGNAL('triggered()'), self, SLOT('collapse_all()'))
    connect(@enable_all_action, SIGNAL('triggered()'), self, SLOT('enable_all()'))
    connect(@diable_all_action, SIGNAL('triggered()'), self, SLOT('disable_all()'))
    connect(@open_action, SIGNAL('triggered()'), self, SLOT('open_config_file()'))
    connect(@save_action, SIGNAL('triggered()'), self, SLOT('save_config_file()'))
    connect(@configs_tree_widget, SIGNAL('itemClicked(QTreeWidgetItem*, int)'),
            self, SLOT('on_item_activated(QTreeWidgetItem*, int)'))
    connect(@descr_text_edit, SIGNAL('anchorClicked(const QUrl&)'), self, SLOT('on_anchor_clicked(const QUrl&)'))
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
  
  def set_config_enable(config_name, is_en)
    @config_define[:"#{config_name}"] = is_en
  end
  
  def open_config_file()
    yaml_wrapper = YamlWrapper.new
    config_name = Qt::FileDialog.getOpenFileName(self)
    if config_name.nil?
      return
    end 
    @config_define = yaml_wrapper.load(config_name)
    @hconfig_utils.build_config_tree({})
    @configs_tree_widget.clear
    load_configs(@hconfig_utils.hconfig_tree)
    expand_all
    resize_column_to_contents(0)
  end
  
  def save_config_file()
    config_file_name = Qt::FileDialog.getSaveFileName(self)
    if config_file_name.nil?
      return
    end 
    @configs_tree_widget.each do |tree_item|
      @config_define[:"#{tree_item.text(0)}"] = ((not tree_item.isDisabled) && (tree_item.checkState(0) == Qt::Checked))
    end
    yaml_wrapper = YamlWrapper.new
    yaml_wrapper.dump(config_file_name, @config_define)
  end
  
  def on_config_define_changed(tree_item, col)
    if col == 0
      config = @tree_item_to_hconfig_map[tree_item]
      if tree_item.checkState(col) == Qt::Checked
        set_config_enable(config[:name], true)
        @hconfig_utils.who_depends_on(config).each do |config_hash|
          # set_config_enable(config[:name], false)
          @hconfig_to_tree_item_map[config_hash].setDisabled(false)
        end
      else
        set_config_enable(config[:name], false)
        @hconfig_utils.who_depends_on(config).each do |config_hash|
          # set_config_enable(config[:name], false)
          @hconfig_to_tree_item_map[config_hash].setDisabled(true)
        end
      end
    end
  end
  
  def on_item_activated(tree_item, col)
    hconfig = @tree_item_to_hconfig_map[tree_item]
    text = hconfig_description(hconfig)
    f = File.new("temp.html", "w+")
    f.write(text)
    f.close
    @descr_text_edit.source = "temp.html"
    @descr_text_edit.reload
    # @descr_text_edit.text = text
  end
  
  def on_anchor_clicked(url)
    urlname = url.toString
    config_name = urlname[urlname.rindex("#") + 1..-1]
    tree_item = @hconfig_to_tree_item_map[@config_name_to_hconfig_map[config_name]]
    @configs_tree_widget.scrollToItem(tree_item)
  end
  
  def enable_all
    @configs_tree_widget.each do |tree_item|
      tree_item.setDisabled(false)
      tree_item.setCheckState(0, Qt::Checked)
    end
  end
  
  def disable_all
    @configs_tree_widget.each do |tree_item|
      tree_item.setDisabled(true)
      tree_item.setCheckState(0, Qt::Unchecked)
    end
  end
  
  def hconfig_description(hconfig_hash)
    ret = '''<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head>'''
    ret +=  "<body>"
    ret +=  "<h1 style='color: blue'>#{hconfig_hash[:name]}</h1>"
    ret +=  "<h2>#{hconfig_hash[:prompt]}</h2>"
    ret +=  "<h3>Depends on:</h3>"
    ret +=  "<ul>#{@hconfig_utils.config_depends(hconfig_hash).map{|x| '<li>[' + 
            config_en_text(x) + ']<a href=#' +  x + '>' + x + '</a></li>'}}</ul>"
    ret +=  "<h3>Depended by:</h3>"
    ret +=  "<ul>#{@hconfig_utils.who_depends_on(hconfig_hash).map{|x| '<li>[' +
            config_en_text(x[:name]) + ']<a href=#' + x[:name] + '>' + x[:name] + '</a></li>'}}</ul>"
    ret +=  "<h3>Help:</h3>"
    ret +=  "<p>#{hconfig_hash[:help]}</p>"
    ret +=  "</body></html>"
    return ret
  end
  
  def config_en?(config_hash)
    tree_item = @hconfig_to_tree_item_map[config_hash]
    return (not tree_item.isDisabled) && (tree_item.checkState(0) == Qt::Checked)
  end
  
  def config_en_text(config_name)
    config_hash = @config_name_to_hconfig_map[config_name]
    return "On" if config_en?(config_hash)
    return "Off"
  end
  
  def load_configs(hconfig_tree)
    @configs_tree_widget.blockSignals(true)
    load_configs_impl(hconfig_tree, @configs_tree_widget)
    @configs_tree_widget.blockSignals(false)
    connect(@configs_tree_widget, 
            SIGNAL('itemChanged(QTreeWidgetItem*, int)'), 
            self, 
            SLOT('on_config_define_changed(QTreeWidgetItem*, int)'))
    
  end
  
  private
  def load_configs_impl(hconfig_tree, parent_tree_widget_item)
    hconfig_tree.each_children do |child|
      config = child.value
      tree_item = Qt::TreeWidgetItem.new(parent_tree_widget_item, [config[:name], config[:prompt]])
      @hconfig_to_tree_item_map[config] = tree_item
      @tree_item_to_hconfig_map[tree_item] = config
      @config_name_to_hconfig_map[config[:name]] = config
      if @config_define.has_key?(:"#{config[:name]}")
        if @config_define[:"#{config[:name]}"] == true
          tree_item.setCheckState(0, Qt::Checked)
        else
          tree_item.setCheckState(0, Qt::Unchecked)
        end
      else
        tree_item.setCheckState(0, Qt::Unchecked)
      end
      @configs_tree_widget.addTopLevelItem(tree_item)
      load_configs_impl(child, tree_item)
    end
  end
end
