require 'set'
require_relative 'libtree/refine_set'
require_relative 'libtree/refine_symbol'
require_relative 'libtree/term'
require_relative 'libtree/base_rule_set'
require_relative 'libtree/substitution'
require_relative 'libtree/homomorphism'
require_relative 'libtree/automaton'
require_relative 'libtree/grammar'
require_relative 'libtree/regular_expression'

module LibTree

  using RefineSet

  def self.define_system(alphabet: , variables: [], states: [])
    Module::new do |m|
      @alphabet = alphabet
      @variables = Set::new(variables)
      @states = states

      def method_missing(m, *args, &block)
        case m
        when /x\d+/
          Term::new(m.to_sym, variable: true)
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

      def self.to_s
        s = "<System: aphabet: {"
        s << @alphabet.collect { |s,arity|
               "#{s}" + (arity > 0 ? "(#{","*(arity-1)})" : "")
             }.join(", ")
        if @variables.length > 0
          s << "}, variables: {"
          s << @variables.to_a.join(", ")
        end
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

      @alphabet.each { |name, arity|
        eval <<EOF
  def #{name}(*children, **opts)
    raise "Invalid child number: \#{children.length}, expected #{arity}" if children.length != #{arity}
    Term::new(#{name.inspect}, *children, **opts)
  end
  def self.#{name}(*children, **opts)
    raise "Invalid child number: \#{children.length}, expected #{arity}" if children.length != #{arity}
    Term::new(#{name.inspect}, *children, **opts)
  end
EOF
      }

      @variables.each { |name|
        eval <<EOF
  def #{name}
    Term::new(#{name.inspect}, variable: true)
  end
  def self.#{name}
    Term::new(#{name.inspect}, variable: true)
  end
EOF
      }

      @states.each_with_index { |state|
        eval <<EOF
    def #{state}( term = nil )
      if term
        t = term.dup
        t.state = #{state.inspect}
        t
      else
        #{state.inspect}
      end
    end
    def self.#{state}( term = nil )
      if term
        t = term.dup
        t.state = #{state.inspect}
        t
      else
        #{state.inspect}
      end
    end
EOF
      }

    end

  end 

end
