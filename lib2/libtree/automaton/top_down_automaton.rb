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

    def epsilon_rules
      @rules.select { |k, _|
        k && k.state? && k.symbol == nil
      }
    end

    def non_epsilon_rules
      @rules.reject { |k, _|
        k && k.state? && k.symbol == nil
      }
    end

    def epsilon_rules?
      ! epsilon_rules.empty?
    end

    def remove_epsilon_rules!
      a = remove_epsilon_rules
      @rules = a.rules
      return self
    end

    def remove_epsilon_rules
      a = to_bottom_up_automaton
      a.remove_epsilon_rules!
      a.to_top_down_automaton
    end

    def to_bottom_up_automaton
      new_rules = RuleSet::new
      non_epsilon_rules.each_rule { |k, p|
        next unless k
        new_k = Term::new(p.symbol, * p.children.collect { |c| c } )
        new_p = k.state
        new_rules.append(new_k, new_p)
      }
      epsilon_rules.each_rule { |k, p|
        new_rules.append(p, k.state)
      }
      Automaton::new(system: @system, states: @states.dup, final_states: @initial_states, rules: new_rules)
    end

    def to_grammar(axiom = nil)
      alpha = @states.collect { |s| [s.to_sym, 0] }.to_h
      new_rules = RegularGrammar::RuleSet::new
      unless axiom
        if @initial_states.size > 1
          axiom = :__new_axiom
          i = 0
          while @states.include? axiom
            axiom = :"__new_axiom#{i}"
            i += 1
          end
          alpha[axiom] = 0
          axiom = Term::new( axiom )
          @initial_states.each { |s|
            new_rules.append(axiom, Term::new( s.to_sym ) )
          }
        else
          axiom = Term::new( @initial_states.first.to_sym )
        end
      end
      non_terminals = LibTree::define_system( alphabet: alpha )
      @rules.each_rule { |k, p|
        next unless k
        new_k = Term::new( k.state )
        new_p = Term::new( p.symbol, *p.children.collect { |c| Term::new( c.dup ) } )
        new_rules.append(new_k, new_p)
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
