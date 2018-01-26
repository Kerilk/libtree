module LibTree

  class TopDownAutomaton < BaseAutomaton
    using RefineSet

    class TopDownRuleSet < RuleSet

      def self.compute_rule(key)
        return key if key.nil?
        super
      end

      def apply(node, rewrite = true)
        s = self[node]
        if s
          s = s.sample if s.kind_of?(Array)
          node.set_symbol s.symbol
          node.children.replace node.children.first.children.each_with_index.collect { |c, i|
            node.class::new( s.children[i].symbol, c )
          }
        else
          raise StopIteration
        end
        self
      end

    end

    class TopDownRun < Run

      def initialize(automaton, tree, rewrite: true)
        @automaton = automaton
        initial = @automaton.rules[nil].sample
        @initial_tree = tree.dup
        @tree = tree.class::new(initial, tree.dup)
        @state = @tree.each(automaton.order)
        @rewrite = rewrite
      end

      def successful?
        @tree == @initial_tree
      end

    end

    @order = :pre

    attr_reader :initial_states

    def initialize( system:, states:, initial_states:, rules:)
      @system = system
      @states = Set[*states]
      @initial_states = Set[*initial_states]
      @rules =  TopDownRuleSet::new
      rules.each { |k, v|
        @rules[k] = v
      }
      @rules[nil] = @initial_states.to_a
    end

    def to_s
      <<EOF
<Automaton:
  system: #{@system}
  states: #{@states.to_s}
  initial_states: #{@initial_states.to_s}
  order: #{order}
  rules:
    #{@rules.rules_to_s("\n    ")}
>
EOF
    end

    def run(tree, rewrite: true)
      TopDownRun::new(self, tree, rewrite: rewrite)
    end

    def deterministic?
      rules.each { |k,v|
        return false if v.kind_of?(Array) && v.length > 1
      }
      true
    end

  end

end
