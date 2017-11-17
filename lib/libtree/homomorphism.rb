module LibTree
  class Homomorphism

    attr_reader :input_system
    attr_reader :output_system
    attr_reader :variables
    attr_reader :rules
    def initialize(input_system:, output_system:, variables:, rules:)
      @input_system = input_system
      @output_system = output_system
      @variables = variables
      input_inter = @input_system.variables & @variables
      output_inter = @output_system.variables & @variables
      raise "Input system shares variables: #{input_inter}!" unless input_inter.empty?
      raise "Output system shares variables: #{output_inter}!" unless output_inter.empty?
      @rules = rules
    end

    def [](term)
      term.morph(self)
    end

  end
end
