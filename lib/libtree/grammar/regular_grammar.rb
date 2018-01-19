module LibTree

  class Grammar
    using RefineSet

    class Derivation
      attr_reader :tree

      def initialize( grammar )
        raise "Grammar is not regular!" unless grammar.regular?
        @grammar = grammar
        @tree = grammar.axiom.dup
        @state = @tree.each(:pre)
      end

      def derive
        node = @state.peek
        @grammar.rules.apply(node)
        @state.next
        return self
      end

      def derivation
        begin
          loop do
            derive
          end
        rescue StopIteration
        end
        @tree
      end

    end #Derivation

    def initialize( axiom:, non_terminals:, terminals:, rules:)
      @axiom = axiom
      @non_terminals = non_terminals
      @terminals = terminals
      @rules =  RuleSet::new
      rules.each { |k, v|
        @rules[k] = v
      }
    end

    def to_s
      <<EOF
<Grammar:
  axiom: #{@axiom.to_s}
  non_terminals: #{@non_terminals}
  terminals: #{@terminals}
  rules:
    #{@rules.collect{ |k,v| "#{k} -> #{v.kind_of?(Array) ? "[#{v.join(", ")}]" : v.to_s}" }.join("\n    ")}
>
EOF
    end

    def regular?
      @non_terminals.each { |nt, arity|
        return false if arity != 0
      }
      @rules.each { |key, value|
        return false unless @non_terminals.alphabet.include?(key.symbol)
      }
      return true
    end

    def derivation
      Derivation::new(self)
    end

  end

end
