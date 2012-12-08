
class Tree
    attr_reader :value
    def initialize(value)
      @value = value
      @children = []
    end
 
    def <<(value)
      subtree = Tree.new(value)
      @children << subtree
      return subtree
    end
 
    def each
      yield value
      @children.each do |child_node|
        child_node.each { |e| yield e }
      end
    end
    
    def has_child?(node)
      
    end
  end