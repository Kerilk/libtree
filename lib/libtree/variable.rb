module LibTree

  class Variable < Term
    using RefineSet

    def height
      0
    end

    def size
      0
    end

    def constant?
      false
    end

    def variable?
      true
    end

    def ground?
      false
    end
    alias ground_term? ground?

    def *(substitution)
      n = substitution.rules[self]
      n ? n.dup : self.dup
    end

  end

end
