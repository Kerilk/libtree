module LibTree

  class Substitution
    using RefineSymbol
    attr_reader :system
    attr_reader :rules
    
    def initialize(system:, rules:)
      vs = rules.keys.collect.to_set
      #raise "Invalid substitution variables: #{vs - system.variables}!" if (vs - system.variables) != Set[]
      @system = system
      @rules = rules
    end

    def ground?
      @rules.each_value { |v|
        return false unless v.ground?
      }
      return true
    end
    alias ground_substitution? ground?

    def domain
      return @rules.collect { |k,v| k unless k == v }.compact.to_set
    end

    def [](term)
      unless term.kind_of?(Term)
        return @rules[term].dup if @rules[term]
        return term.dup
      end
      return term * self
    end

  end

end
