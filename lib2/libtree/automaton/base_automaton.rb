module LibTree

  class BaseAutomaton
    using RefineSet

    class Equivalence < Set

      def equivalent?(s1, s2)
        self.each { |subset|
          return false unless ( subset.include?(s1) == subset.include?(s2) )
        }
        true
      end

      def equivalence(s)
        self.each { |subset|
          return subset if subset.include?(s)
        }
        nil
      end

    end

    # Ground rewrite rule set
    class RuleSet < BaseRuleSet

      class Rule < Term

        def size
          arity + 2
        end

      end #Rule

      def self.compute_rule(key)
        if key.kind_of?(Term)
          r = Rule::new(key.symbol, state: key.state)
          r.children.push *key.children.collect { |c| c.kind_of?(Term) ? c.to_state : Term::new(nil, state: c) } unless r.state?
        else
          r = Rule::new(nil, state: key)
        end
        r
      end

      def rules_size
        @hash.collect { |k,v| k.size * v.size }.inject(&:+)
      end

      def apply(node)
        s = self[node]
        if s
          s = s.sample
          node.children.each { |c| c.state = nil }
          node.state = s
        end
        self
      end

    end #RuleSet

    class Run
      attr_reader :tree

      def initialize(automaton, tree)
        tree.clear_states
        @automaton = automaton.remove_epsilon_rules
        @tree = tree
        @state = @tree.each(automaton.order)
        @successful = nil
      end

      def move
        node = @state.next
        @automaton.rules.apply(node)
        return self
      end

      def successful?
        if @successful.nil?
          @successful = @automaton.final_states.include?(@tree.state)
          @tree.clear_states
        end
        @successful
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

    attr_reader :system
    attr_reader :rules
    attr_reader :states

    def self.order
      @order
    end

    def order
      self.class.order
    end

    def deterministic?
      return false if epsilon_rules?
      rules.each { |_,v|
        return false if v.length > 1
      }
      true
    end

  end

end
