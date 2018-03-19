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

    @m3 = Module::new do
      extend terminals
      class << self
        attr_reader :list_0
        attr_reader :tree_0
        attr_reader :list_1
        attr_reader :tree_1
        attr_reader :list_2
        attr_reader :tree_2
        attr_reader :list_plus
        attr_reader :tree_3
      end

      @list_0 = cons(s(sq)**:* / zero, sq)**0 / void
      @list_1 = cons(s(sq)**:* / zero, sq)**1 / void
      @list_2 = cons(s(sq)**:* / zero, sq)**2 / void
      @list_plus = cons(s(sq)**:* / zero, sq)**:+ / void
      @tree_0 = void
      @tree_1 = cons(s(s(zero)),void)
      @tree_2 = cons(s(zero), cons(zero, void))
      @tree_3 = cons(s(s(s(zero))), cons(s(zero), cons(zero, void)))
    end

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

  def test_numbered_iteration
    a = @m3.list_0.to_grammar.bottom_up_automaton.determinize

    r0 = a.run(@m3.tree_0)
    assert(r0.run)
    r1 = a.run(@m3.tree_1)
    refute(r1.run)
    r2 = a.run(@m3.tree_2)
    refute(r2.run)
    r3 = a.run(@m3.tree_3)
    refute(r3.run)

    a = @m3.list_1.to_grammar.bottom_up_automaton.determinize
    r0 = a.run(@m3.tree_0)
    refute(r0.run)
    r1 = a.run(@m3.tree_1)
    assert(r1.run)
    r2 = a.run(@m3.tree_2)
    refute(r2.run)
    r3 = a.run(@m3.tree_3)
    refute(r3.run)

    a = @m3.list_2.to_grammar.bottom_up_automaton.determinize 
    r0 = a.run(@m3.tree_0)
    refute(r0.run)
    r1 = a.run(@m3.tree_1)
    refute(r1.run)
    r2 = a.run(@m3.tree_2)
    assert(r2.run)
    r3 = a.run(@m3.tree_3)
    refute(r3.run)

    a = @m3.list_plus.to_grammar.bottom_up_automaton.determinize
    r0 = a.run(@m3.tree_0)
    refute(r0.run)
    r1 = a.run(@m3.tree_1)
    assert(r1.run)
    r2 = a.run(@m3.tree_2)
    assert(r2.run)
    r3 = a.run(@m3.tree_3)
    assert(r3.run)
  end

end
