module LibTree
  module RefineSet
    using RefineSet
    refine Set do
      def to_s
        "{#{each.collect{ |e| e.to_s}.join(", ")}}"
      end
    end
  end
end
