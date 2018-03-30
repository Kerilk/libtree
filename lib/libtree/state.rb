require 'delegate'

module LibTree

  class State < SimpleDelegator

    def initialize(sym)
      super.to_sym
      def self.eql?(other)
        self == other
      end
    end

    def dup
      return State::new(__getobj__)
    end

    def kind_of?(klass)
      res = super
      res ? res : __getobj__.kind_of?(klass)
    end

    def ==(other)
      if other.kind_of? State
        __getobj__ == other.__getobj__
      else
        __getobj__ == other
      end
    end

  end

end

