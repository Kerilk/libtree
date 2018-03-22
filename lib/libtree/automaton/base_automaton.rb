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
        return key if key.kind_of?(Symbol)
        r = Rule::new(key.symbol)
        r.children.push *key.children.collect { |c| c.kind_of?(Term) ? c.symbol : c }
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

      def apply(node, rewrite = true, capture = nil)
        s = self[node]
        if s
          s = s.sample
          cap = nil
          if s.kind_of? CaptureState
            cap = s.capture_group
            s = s.state
          end
          if s.kind_of? Term
            s = s.symbol
          end
          if rewrite
            node.set_symbol s
            if capture && cap
              cap.each { |position, name|
                child = node.children[position]
                raise "Invalid capture position: #{position} for #{node}!" if child.nil?
                capture[name].push child
              }
            end
          else
            new_node = node.class::new(node.symbol, *node.children)
            node.set_symbol s
            if node.arity > 0
              new_node.children.collect! { |c| c.children.first }
            end
            node.children.replace [new_node]
            if capture && cap
              cap.each { |position, name|
                child = new_node.children[position]
                raise "Invalid capture position: #{position} for #{new_node}!" if child.nil?
                capture[name].push child
              }
            end
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
        @capture = Hash::new { |hash, key| hash[key] = [] }
        @automaton = automaton.remove_epsilon_rules
        @tree = tree.dup
        @state = @tree.each(automaton.order)
        @rewrite = rewrite
      end

      def move
        node = @state.next
        @automaton.rules.apply(node, @rewrite, @capture)
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

      def matches
        return {} unless successful?
        return @capture
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
