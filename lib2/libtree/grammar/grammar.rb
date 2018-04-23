module LibTree

  class Grammar
    using RefineSet

    class RuleSet < BaseRuleSet

      def apply(node)
        s = self[node]
        if s
          s = s.sample
          node.set_symbol s.symbol
          node.children.replace( s.children.collect { |c| c.dup } )
        end
        self
      end

    end #RuleSet

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

    attr_reader :axiom, :non_terminals, :terminals, :rules
    def initialize( axiom:, non_terminals:, terminals:, rules:)
      @non_terminals = non_terminals.dup
      raise "Grammar's axiom must be a non terminal!" unless @non_terminals.alphabet.include?(axiom.symbol) && @non_terminals.alphabet[axiom.symbol] == axiom.arity
      @axiom = axiom.dup
      @terminals = terminals.dup
      @rules =  RuleSet::new
      rules.each { |k, v|
        @rules.append(k.dup, v.collect { |p| p.dup })
      }
    end

    def dup
      self.class::new( axiom: @axiom, non_terminals: @non_terminals, terminals: @terminals, rules: @rules)
    end

    def axiom=(new_axiom)
      raise "Grammar's axiom must be a non terminal!" unless @non_terminals.alphabet.include?(new_axiom.symbol) && @non_terminals.alphabet[new_axiom.symbol] == new_axiom.arity
      @axiom = new_axiom
    end

    def set_axiom(new_axiom)
      raise "Grammar's axiom must be a non terminal!" unless @non_terminals.alphabet.include?(new_axiom.symbol) && @non_terminals.alphabet[new_axiom.symbol] == new_axiom.arity
      @axiom = new_axiom
      self
    end

    def to_s
      <<EOF
<Grammar:
  axiom: #{@axiom.to_s}
  non_terminals: #{@non_terminals}
  terminals: #{@terminals}
  rules:
    #{@rules.rules_to_s("\n    ")}
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
