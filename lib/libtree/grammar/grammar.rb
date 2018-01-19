module LibTree

  class Grammar
    using RefineSet

    class RuleSet < Hash

    end #RuleSet

    attr_reader :axiom, :non_terminals, :terminals, :rules
  end

end
