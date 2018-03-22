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
      if @rules[term]
        return @rules[term].dup
      else
        if term.kind_of?(Term) || term.kind_of?(CaptureState)
          return term * self
        else
          return term.dup
        end
      end
    end

  end

end
