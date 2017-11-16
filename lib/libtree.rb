require 'set'
require_relative 'libtree/refine_set'
require_relative 'libtree/term'
require_relative 'libtree/variable'
require_relative 'libtree/substitution'
require_relative 'libtree/automaton'

module LibTree

  using RefineSet

  def self.define_system(alphabet: , variables:)
    Module::new do |m|
      @alphabet = alphabet
      @variables = Set::new(variables)

      def self.substitution(**rules)
        Substitution::new(self, **rules)
      end

      def self.arity(sym)
        @alphabet[sym]
      end

      def self.variables
        @variables.dup
      end

      def self.alphabet
        @alphabet.dup
      end

      define_method(:arity) { |sym|
        m.arity(sym)
      }

      define_method(:substitution) { |**rules|
        m.substitution(**rules)
      }

      define_method(:variables) {
        m.variables
      }

      define_method(:alphabet) {
        m.alphabet
      }

      @alphabet.each { |name, arity|
        eval <<EOF
  def #{name}(*children)
    raise "Invalid child number: \#{children.length}, expected #{arity}" if children.length != #{arity}
    Term::new(#{name.inspect}, *children)
  end
  def self.#{name}(*children)
    raise "Invalid child number: \#{children.length}, expected #{arity}" if children.length != #{arity}
    Term::new(#{name.inspect}, *children)
  end
EOF
      }

      @variables.each { |name|
        eval <<EOF
  def #{name}
    Variable::new(#{name.inspect})
  end
  def self.#{name}
    Variable::new(#{name.inspect})
  end
EOF
      }
    end
  end 

end
