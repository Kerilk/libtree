module LibTree

  class Term
    attr_reader :children
    attr_reader :symbol
    def initialize(symbol, *children)
      @symbol = symbol
      @children = children
    end

    def arity
      @children.length
    end

    def to_s
      "#{symbol}#{arity > 0 ? "(#{children.join(',')})" : ""}"
    end

    def root
      @symbol
    end

    alias head root

    def dup
      children = @children.collect { |c| c.dup }
      t = self.class::new(@symbol, *children)
      return t
    end

    def ==(other)
      return false unless @symbol == other.symbol && @children.length == other.children.length
      @children.each_with_index { |c,i|
        return false unless c == other.children[i]
      }
      return true
    end

    def >=( other )
      return true if self == other
      return self > other
    end

    def >( other )
      @children.each { |c|
        return true if c >= other
      }
      return false
    end

    def <=( other )
      return true if self == other
      return self < other
    end

    def <( other )
      other.children.each { |c|
        return true if self <= c
      }
      return false
    end

    def []=(*position, value)
      position.flatten!
      pos = position.shift
      if pos
	if position == []
          @children[pos] = value
        else
          @children[pos][*position] = value
        end
      end
    end

    def [](*position)
      position.flatten!
      pos = position.shift
      if pos
        @children[pos][*position]
      else
        @symbol
      end
    end

    def linear?
      set = Set::new
      variable_positions.each { |p|
        return false unless set.add?(self[*p])
      }
      true
    end
    alias context? linear?

    def ground?
      return variable_positions == Set[]
    end
    alias ground_term? ground?

    def |(position)
      position = [position] if !position.kind_of?(Array)
      pos = position.shift
      if pos
        @children[pos]|position
      else
	self
      end
    end

    def height
      return 1 if arity == 0
      1 + children.collect(&:height).max
    end

    def size
      return 1 if arity == 0
      1 + children.collect(&:size).reduce(&:+)
    end

    def positions
      return Set[] if arity == 0
      pos = (0...arity).collect { |i| [i] }
      children_pos = []
      children.collect(&:positions).each_with_index { |ps,i|
        ps.each { |p|
          children_pos.push pos[i]+p
        }
      }
      Set[*(pos + children_pos)]
    end

    def frontier_positions
      return Set[] if arity == 0
      pos = (0...arity).collect { |i| [i] }
      children_pos = []
      children.collect(&:frontier_positions).each_with_index { |ps,i|
	if ps == Set[]
          children_pos.push pos[i]
        else
          ps.each { |p|
            children_pos.push pos[i]+p
          }
        end
      }
      Set[*children_pos]
    end

    def variable_positions
      return Set[] if arity == 0
      pos = (0...arity).collect { |i| [i] }
      children_pos = []
      children.collect(&:variable_positions).each_with_index { |ps,i|
        if ps == Set[] and children[i].kind_of?(Variable)
          children_pos.push pos[i]
        else
          ps.each { |p|
              children_pos.push pos[i]+p
          }
        end
      }
      Set[*children_pos]
    end

    def *(substitution)
      Term::new(@symbol, *(@children.collect{ |c| c * substitution  } ))
    end
#    def *(substitution)
#      t = self.dup
#      variable_positions.each { |p|
#        sym = t[p]
#        r = substitution.rules[sym]
#        t[p] = r if r
#      }
#      t
#    end

  end

end
