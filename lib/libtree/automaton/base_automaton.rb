module LibTree

  class BaseAutomaton
    using RefineSet

    class Equivalence < Set

      def equivalent?(s1, s2)
        self.each { |subset|
          return false if subset.include?(s1) && !subset.include?(s2)
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
        return key if key.kind_of?(Symbol)
        r = Rule::new(key.symbol)
        r.children.push *key.children.collect { |c| c.kind_of?(Term) ? c.symbol : c }
        r
      end

      def include?(key)
        super(self.class::compute_rule(key))
      end

      def [](key)
        super(self.class::compute_rule(key))
      end

      def []=(key,value)
        super(self.class::compute_rule(key), value)
      end

      def delete(key)
        super(self.class::compute_rule(key))
      end

      def rules_size
        collect { |k,v| k.size * ( v.kind_of?(Array) ? v.size : 1 ) }.inject(&:+)
      end

      def apply(node, rewrite = true)
        s = self[node]
        if s
          s = s.sample if s.kind_of?(Array)
          if rewrite
            node.set_symbol s
          else
            new_node = node.class::new(node.symbol, *node.children)
            node.set_symbol s
            if node.arity > 0
              new_node.children.collect! { |c| c.children.first }
            end
            node.children.replace [new_node]
          end
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

      def initialize(automaton, tree, rewrite: true)
        @automaton = automaton.remove_epsilon_rules
        @tree = tree.dup
        @state = @tree.each(automaton.order)
        @rewrite = rewrite
      end

      def move
        node = @state.next
        @automaton.rules.apply(node, @rewrite)
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
