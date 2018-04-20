module LibTree

  module TermMethods

    def arity
      @children.length
    end

    def root
      @symbol
    end

    alias head root

    def each_post_order(&block)
      if block_given?
        @children.each { |c|
          c.each_post_order(&block)
        }
        yield self
        return self
      else
        to_enum(:each_post_order)
      end
    end

    def each_pre_order(&block)
      if block_given?
        yield self
        @children.each { |c|
          c.each_pre_order(&block)
        }
        return self
      else
        to_enum(:each_pre_order)
      end
    end

    def each(order = :post, &block)
      case order
      when :pre
        each_pre_order(&block)
      when :post
        each_post_order(&block)
      else
        raise "Unknown traversal order: #{order}!"
      end
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
      return false if variable?
      return variable_positions == Set[]
    end
    alias ground_term? ground?

    def constant?
      return false if variable?
      return @children.length == 0
    end

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
      return 0 if variable?
      return 1 if arity == 0
      1 + @children.collect(&:height).max
    end

    def size
      return 0 if variable?
      return 1 if arity == 0
      1 + @children.collect(&:size).reduce(&:+)
    end

    def positions
      return Set[] if arity == 0
      pos = (0...arity).collect { |i| [i] }
      children_pos = []
      @children.collect(&:positions).each_with_index { |ps,i|
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
      @children.collect(&:frontier_positions).each_with_index { |ps,i|
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
        if ps == Set[] and children[i].variable?
          children_pos.push pos[i]
        else
          ps.each { |p|
              children_pos.push pos[i]+p
          }
        end
      }
      Set[*children_pos]
    end

  end

  class Term
    using RefineSymbol
    using RefineSet
    include TermMethods
    attr_reader :children
    attr_reader :symbol
    attr_accessor :state
    attr_reader :variable

    def set_symbol(symbol)
      @symbol = symbol
    end

    def state?
      return !!state
    end

    def variable?
      return variable
    end

    def capture?
      return !!capture
    end

    def initialize(symbol, *children, state: nil, variable: false)
      @symbol = symbol
      @children = children.dup
      @state = state
      @variable = variable
    end

    def to_var
      Term::new(@symbol, variable: true)
    end

    def to_state
      Term::new(nil, state: @state)
    end

    def rename_states(mapping)
      @state = mapping[@state] if @state
      @children.each { |c|
        c.rename_states(mapping)
      }
      self
    end

    def clear_states
      @state = nil
      @children.each { |c|
        c.clear_states
      }
      self
    end

    def dup
      children = @children.collect { |c| c.dup }
      t = self.class::new(@symbol, *children, state: @state, variable: @variable)
      return t
    end

    def ==(other)
      other.kind_of?(Term) && ( @symbol == other.symbol || other.symbol == @symbol ) && @state == other.state && @children == other.children
    end

    alias eql? ==

    def hash
      @symbol.hash ^ @children.hash ^ @state.hash
    end

    def *(substitution)
      if variable?
        n = substitution.rules[self]
        n ? n.dup : self.dup
      else
        Term::new(@symbol, *(@children.collect{ |c| substitution[c]  } ))
      end
    end

    def morph(morphism)
      if morphism.rules[@symbol]
        t = morphism.rules[@symbol]
        vars = morphism.variables.take(arity)
        s_rules = vars.zip @children.collect{ |c| c.morph(morphism) }
        s = morphism.output_system.substitution( rules: s_rules.to_h )
        t * s
      else
        Term::new(@symbol, *(@children.collect{ |c| c.morph(morphism) } ))
      end
    end

    def to_s
      str = "#{@symbol.to_s}#{arity > 0 ? "(#{@children.collect{ |e| e.to_s}.join(',')})" : ""}"
      if @state
        str = "#{state.to_s}#{@symbol ? "(#{str})" : "" }"
      end
      str
    end

  end

end
