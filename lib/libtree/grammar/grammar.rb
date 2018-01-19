module LibTree

  class Grammar
    using RefineSet

    class RuleSet < Hash

      def apply(node)
        s = self[node]
        if s
          s = s.sample if s.kind_of?(Array)
          node.set_symbol s.symbol
          node.children.replace( s.children.collect { |c| c.dup } )
        end
        self
      end

    end #RuleSet

    attr_reader :axiom, :non_terminals, :terminals, :rules
  end

end
