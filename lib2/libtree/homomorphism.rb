module LibTree
  class Homomorphism

    attr_reader :input_system
    attr_reader :output_system
    attr_reader :variables
    attr_reader :rules

    #unspecified rule is identity
    def initialize(input_system:, output_system:, variables:, rules:)
      @input_system = input_system
      @output_system = output_system
      @variables = variables
      input_inter = @input_system.variables & @variables
      output_inter = @output_system.variables & @variables
      raise "Input system shares variables: #{input_inter}!" unless input_inter.empty?
      raise "Output system shares variables: #{output_inter}!" unless output_inter.empty?
      @rules = rules.dup
      @rules.each { |k,v|
        unless v.kind_of?(Term)
          @rules[k] = Term::new(v, variable: true)
        end
      }
    end

    def linear?
      @rules.each { |k,v|
        vars = @variables.take(@input_system.arity(k))
        v_vars = v.variable_positions.collect { |p|
          Term::new(v[p], variable: true)
        }
        vars.each { |variable|
          return false unless v_vars.count(variable) <= 1
        }
      }
      return true
    end

    def epsilon_free?
      @rules.each { |k,v|
        return false if v.variable?
      }
      return true
    end

    def symbol_to_symbol?
      @input_system.alphabet.each { |symbol, arity|
        r = @rules[symbol]
        if r
          return false unless r.height == 1
        end
      }
      return true
    end

    def complete?
      @rules.each { |k,v|
        vars = @variables.take(@input_system.arity(k))
        v_vars = v.variable_positions.collect { |p| Term::new(v[p], variable: true) }
        vars.each { |variable|
          return false unless v_vars.count(variable) == 1
        }
      }
      return true
    end

    def delabeling?
      complete? && linear? && symbol_to_symbol?
    end

    def alphabetic?
      @input_system.alphabet.each { |symbol, arity|
        r = @rules[symbol]
        if r
          return false unless r.height == 1
          vars = @variables.take(arity)
          r_vars = r.variable_positions.collect { |p| Term::new(r[p], variable: true) }
          return false unless (r_vars & vars) == vars
        end
      }
      return true
    end
    alias relabeling? alphabetic?

    def [](term)
      term.morph(self)
    end

  end
end
