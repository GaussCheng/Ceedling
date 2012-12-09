
class Tree
    attr_reader :value, :children
    def initialize(value)
      @value = value
      @children = []
    end
 
    def <<(value)
      subtree = Tree.new(value)
      @children << subtree
      return subtree
    end
    
    def empty?
      return @children.empty?
    end
 
    def each
      yield value
      @children.each do |child_node|
        child_node.each { |e| yield e }
      end
    end
    
    def children
      @children
    end
    
    def has_child?(node)
      self.each do |child|
        if child == node
          return true
        end
      end
      return false
    end
    
    def to_str
      ret = ""
      self.each do |node|
        ret += node
      end
      return ret
    end
  end