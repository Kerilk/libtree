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

      @nat = void + cons(s(sq1).**(:*, sq1)./(sq1, zero), sq2).**(:*, sq2)./(sq2, void)
    end

    @nat = @m.nat

    @m2 = Module::new do
      extend terminals
      class << self
        attr_reader :nat
      end

      @nat = void + cons(s(sq)**:* / zero, sq)**:* / void
    end

    @nat2 = @m2.nat

  end

  def test_regular_expression
    g = @nat.to_grammar
    a = g.bottom_up_automaton
    a.minimize!.rename_states
    g2 = a.to_grammar
    assert_equal( <<EOF, g2.reduce.to_s )
<Grammar:
  axiom: qr0
  non_terminals: <System: aphabet: {qr0, qr1}>
  terminals: <System: aphabet: {void, s(), zero, cons(,)}>
  rules:
    qr0 -> [void, cons(qr1,qr0)]
    qr1 -> [s(qr1), zero]
>
EOF
  end

  def test_implicit_regular_expression
    g = @nat2.to_grammar
    assert_equal(@nat.to_grammar.to_s, g.to_s)
  end

end
