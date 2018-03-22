module LibTree

  class CaptureState
    using RefineSymbol

    attr_reader :state, :capture_group

    def initialize(state, capture_groups)
      @state = state
      @capture_group = capture_groups
    end

    def to_s
      "#{@state}(#{@capture_group})"
    end

    def *(substitution)
      new_state = @state.dup
      if new_state.kind_of?( Term ) && substitution.rules[new_state.symbol]
        new_state.set_symbol( substitution.rules[new_state.symbol] )
      end
      CaptureState::new( substitution[new_state], @capture_group.dup )
    end

    def dup
      CaptureState::new( @state.dup, @capture_group.dup )
    end

  end

end

