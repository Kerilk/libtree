require 'set'
require 'minitest/autorun'
require_relative '../lib/libtree'

class TestRegularExpression < Minitest::Test
  def setup
    terminals = LibTree::define_system( alphabet: { zero: 0, void: 0, s: 1, cons: 2 })

    @m = Module::new do
      extend terminals
      class << self
        attr_reader :nat
      end

      @nat = cons(s(sq1).**(:*, sq1)./(sq1, zero), sq2).**(:*, sq2)./(sq2, void)
    end

    @nat = @m.nat
  end

  def test_regular_expression
    g = @nat.to_grammar
    puts g
    a = g.bottom_up_automaton
    puts a
    a.minimize!.rename_states
    puts a
    g2 = a.to_grammar
    puts g2
    puts g2.reduce
  end

end
