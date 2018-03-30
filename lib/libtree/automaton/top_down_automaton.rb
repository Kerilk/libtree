module LibTree

  class TopDownAutomaton < BaseAutomaton
    using RefineSet

    class TopDownRuleSet < RuleSet

      def self.compute_rule(key)
        return key if key.nil?
        super
      end

      def apply(node, rewrite = true, capture = nil)
        s = self[node]
        if s
          s = s.sample
          cap = s.capture
          node.set_symbol s.symbol
          if capture && cap
            cap.each { |position, name|
              child = node.children.first.children[position]
              raise "Invalid capture position: #{position} for #{node}!" if child.nil?
              capture[name].push child
            }
          end
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
        @capture = Hash::new { |hash, key| hash[key] = [] }
        @automaton = automaton
        initial = @automaton.rules[nil].sample
        @initial_tree = tree.dup
        @tree = Term::new(initial.symbol, tree.dup)
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
          cap = p.capture
          new_k = Term::new(p.symbol, * p.children.collect { |c| c } )
          new_p = Term::new(k.symbol, capture: cap)
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
      TopDownRun::new(self, tree, rewrite: rewrite)
    end

    def deterministic?
      rules.each { |k,v|
        return false if v.length > 1
      }
      true
    end

  end

end
