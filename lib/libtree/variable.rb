module LibTree

  class Variable < Term

    def height
      0
    end

    def size
      0
    end

    def ground?
      false
    end
    alias ground_term? ground?

    def *(substitution)
      n = substitution.rules[@symbol]
      n ? n : self.dup
    end

  end

end
