module LibTree

  class TopDownAutomaton < BaseAutomaton
    using RefineSet

    class TopDownRuleSet < RuleSet

      def self.compute_rule(key)
        return key if key.nil?
        super
      end

      def apply(node)
        s = self[node]
        if s
          s = s.sample
          node.state = nil
          node.children.each_with_index { |c, i|
            c.state = s.children[i]
          }
        else
          raise StopIteration
        end
        self
      end

    end

    class TopDownRun < Run

      def initialize(automaton, tree)
        @automaton = automaton
        @tree = tree.dup
        @state = @tree.each(automaton.order)
        @tree.state = @automaton.rules[nil].sample
      end

      def successful?
        @tree.each { |t|
          return false if t.state
        }
        return true
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
        v = [ v ] unless v.kind_of?(Array)
        v.each { |p|
          @rules.append(k.dup, p.dup)
        }
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

    def to_bottom_up_automaton
      new_rules = RuleSet::new
      @rules.each { |k, v|
        next unless k
        v.each { |p|
          new_k = Term::new(p.symbol, * p.children.collect { |c| c } )
          new_p = k.state
          new_rules.append(new_k, new_p)
        }
      }
      Automaton::new(system: @system, states: @states.dup, final_states: @initial_states, rules: new_rules)
    end

    def to_grammar(axiom = nil)
      axiom = Term::new( @initial_states.first.symbol.to_sym ) unless axiom
      non_terminals = LibTree::define_system( alphabet: @states.collect { |s| [s.symbol.to_sym, 0] }.to_h )
      new_rules = RegularGrammar::RuleSet::new
      @rules.each { |k,v|
        next unless k
        v.each { |p|
          cap = p.capture
          new_k = Term::new( k.symbol.to_sym )
          new_p = Term::new( p.symbol.to_sym, *p.children.collect { |c| c.dup }, capture: cap )
          new_rules.append(new_k, new_p)
        }
      }
      RegularGrammar::new(axiom: axiom, non_terminals: non_terminals, terminals: @system, rules: new_rules)
    end

    def run(tree, rewrite: true)
      TopDownRun::new(self, tree)
    end

    def deterministic?
      rules.each { |k,v|
        return false if v.length > 1
      }
      true
    end

  end

end
