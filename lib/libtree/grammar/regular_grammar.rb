module LibTree

  class Grammar
    using RefineSet

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
        return false unless @non_terminals.include?(key.symbol)
      }
      return true
    end

  end

end
