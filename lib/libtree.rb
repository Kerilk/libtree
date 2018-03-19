require 'set'
require_relative 'libtree/refine_set'
require_relative 'libtree/refine_symbol'
require_relative 'libtree/term'
require_relative 'libtree/variable'
require_relative 'libtree/substitution'
require_relative 'libtree/automaton'
require_relative 'libtree/homomorphism'
require_relative 'libtree/grammar'
require_relative 'libtree/regular_expression'

module LibTree

  using RefineSet

  def self.define_system(alphabet: , variables: [], states: [])
    Module::new do |m|
      @alphabet = alphabet
      @variables = Set::new(variables)
      @states = Set::new(states)

      def method_missing(m, *args, &block)
        case m
        when /x\d+/
          Variable::new(m.to_sym)
        when /sq\d*/
          Square::new(m.to_sym)
        else
          super
        end
      end

      def self.substitution(rules:)
        Substitution::new(system: self, rules: rules)
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

      def self.states
        @states.dup
      end

      def self.to_s
        s = "<System: aphabet: {"
        s << @alphabet.collect { |s,arity|
               "#{s}" + (arity > 0 ? "(#{","*(arity-1)})" : "")
             }.join(", ")
        if @variables.length > 0
          s << "}, variables: {"
          s << @variables.to_a.join(", ")
        end
#        if @states.length > 0
#          s << "}, states: {"
#          s << @states.to_a.join(", ")
#        end
        s << "}>"
        s
      end

      def self.each(*args, &block)
        @alphabet.each(*args, &block)
      end

      define_method(:arity) { |sym|
        m.arity(sym)
      }

      define_method(:substitution) { |rules:|
        m.substitution(rules: rules)
      }

      define_method(:variables) {
        m.variables
      }

      define_method(:alphabet) {
        m.alphabet
      }

      define_method(:states) {
        m.states
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

      @states.each { |name|
        eval <<EOF
  def #{name}(*children)
    Term::new(#{name.inspect}, *children)
  end
  def self.#{name}(*children)
    Term::new(#{name.inspect}, *children)
  end
EOF
      }
    end
  end 

end
