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
    class RuleSet < Hash

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

      def to_s(separator = ", ")
        "<RuleSet: #{rules_to_s(separator)}>"
      end

      def rules_to_s(separator = ", ")
        "#{collect{ |k,v| "#{k} -> #{v.length > 1 ? "[#{v.join(", ")}]" : v.first.to_s}" }.join(separator)}"
      end

      def include?(key)
        super(self.class::compute_rule(key))
      end

      def [](key)
        super(self.class::compute_rule(key))
      end

      def []=(key,value)
        raise "invalid rule!" unless value.kind_of?(Array)
        super(self.class::compute_rule(key), value)
      end

      def delete(key)
        super(self.class::compute_rule(key))
      end

      def rules_size
        collect { |k,v| k.size * v.size }.inject(&:+)
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

      def append(key, value)
        value = [value] unless value.kind_of?(Array)
        if self.include?(key)
          old_value = self[key]
          self[key] = (old_value + value).uniq
        else
          self[key] = value
        end
      end

    end #RuleSet

    class Run
      attr_reader :tree

      def initialize(automaton, tree)
        @automaton = automaton.remove_epsilon_rules
        @tree = tree.dup
        @state = @tree.each(automaton.order)
      end

      def move
        node = @state.next
        @automaton.rules.apply(node)
        return self
      end

      def successful?
        @automaton.final_states.include?(tree.state)
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

  end

end
