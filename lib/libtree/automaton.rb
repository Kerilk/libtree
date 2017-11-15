module LibTree

  class Automaton

    class RuleSet < Hash

      class Rule < Term
        def hash
        end

        def ==(other)
          self.class === other && @symbol == other.symbol && @children == other.children
        end

        alias eql? ==

        def hash
          @symbol.hash ^ @children.hash
        end

      end #Rule
      
      def [](key)
        super(Rule::new(key.symbol, *key.children.collect { |c| c.kind_of?(Term) ? c.symbol : c }))
      end

      def []=(key,value)
        super(Rule::new(key.symbol, *key.children.collect { |c| c.kind_of?(Term) ? c.symbol : c }), value)
      end

    end #RuleSet

    attr_reader :system
    attr_reader :rules
    attr_reader :states
    attr_reader :final_states
    attr_reader :order
    def initialize( system:, states:, final_states:, rules:, order: :post)
      @system = system
      @states = Set[*states]
      @final_states = Set[*final_states]
      @rules =  RuleSet::new
      rules.each { |k, v|
        @rules[k] = v
      }
      @order = order
    end

    def ==(other)
      self.class === other && @system == other.system && @rules == other.rules && @states == other.states && @final_states == other.final_states
    end

    alias eql? ==

    def dup
      Automaton::new( system: @system, states: @states.to_a, final_states: @final_states.to_a, rules: @rules, order: @order )
    end

    def deterministic?
      rules.each { |k,v|
        return false if v.kind_of?(Array)
      }
      true
    end

    def complete?
      @system.alphabet.each { |sym, arity|
        if arity > 0
          @states.to_a.repeated_permutation(arity) { |perm|
            return false unless rules[@system.send(sym, *perm)]
          }
        else
          return false unless rules[@system.send(sym)]
        end
      }
      return true
    end

    def complete!
      return self if complete?
      @states.add(:__dead)
      @system.alphabet.each { |sym, arity|
        if arity > 0
          @states.to_a.repeated_permutation(arity) { |perm|
            @rules[@system.send(sym, *perm)] = :__dead unless rules[@system.send(sym, *perm)]
          }
        else
          @rules[@system.send(sym)] = :__dead unless rules[@system.send(sym)]
        end
      }
      return self
    end

    def complete
      dup.complete!
    end

  end #Automaton

  class Run
    attr_reader :tree

    def initialize(automaton, tree)
      @automaton = automaton
      @tree = tree.dup
      @state = @tree.each(automaton.order)
    end

    def move
      node = @state.next
      s = @automaton.rules[node]
      if s
        if s.kind_of?(Array)
          node.set_symbol s.sample
        else
          node.set_symbol s
        end
      end
      return self
    end

    def successful?
      @automaton.final_states.include?(@tree.root)
    end

    def run
      begin
        loop do
          move
        end
      rescue StopIteration
      end
      successful?
    end

  end

end
