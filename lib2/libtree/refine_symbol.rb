module LibTree
  module RefineSymbol
    using RefineSymbol
    refine Symbol do
      def dup
        return self
      end
    end
  end
end
