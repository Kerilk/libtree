require 'set'
require 'minitest/autorun'
require_relative '../lib/libtree'

class TestGrammar < Minitest::Test

  def setup

    non_terminals = LibTree::define_system( alphabet: { list: 0, nat: 0 })
    terminals = LibTree::define_system( alphabet: { zero: 0, void: 0, s: 1, cons: 2 })
    @m = Module::new do
      extend terminals
      extend non_terminals
      class << self
        attr_reader :grammar
      end

      @grammar = LibTree::Grammar::new( axiom: list, non_terminals: non_terminals , terminals: terminals, rules: {
        list => [ void, cons(nat, list)],
        nat => [ zero, s(nat) ]
      } )
    end

    @g = @m.grammar

    @m2 = Module::new do
      extend terminals
      extend non_terminals
      class << self
        attr_reader :grammar
      end

      @grammar = LibTree::RegularGrammar::new( axiom: list, non_terminals: non_terminals , terminals: terminals, rules: {
        list => [ void, cons(nat, list)],
        nat => [ zero, s(nat) ]
      } )
    end

    @rg = @m2.grammar

    @m3 = Module::new do
      extend terminals
      extend non_terminals
      class << self
        attr_reader :grammar
      end

      @grammar = LibTree::RegularGrammar::new( axiom: list, non_terminals: non_terminals , terminals: terminals, rules: {
        list => [ void, cons(nat, list), cons(nat, cons(nat, list))],
        nat => [ zero, s(nat) ]
      } )
    end

    @rg2 = @m3.grammar
  end

  def test_grammar
    assert_equal( <<EOF, @g.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {list, nat}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    list -> [void, cons(nat,list)]
    nat -> [zero, s(nat)]
>
EOF
    assert( @g.regular? )
    d = @g.derivation
    assert( d.derivation, LibTree::Term )
  end

  def test_regular_grammar
    assert_equal( <<EOF, @rg.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {list, nat}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    list -> [void, cons(nat,list)]
    nat -> [zero, s(nat)]
>
EOF
    assert( @rg.regular? )
    d = @rg.derivation
    assert_equal( LibTree::Term, d.derivation.class )
    assert_equal( LibTree::RegularGrammar, @rg.dup.class )
    assert_equal( Set[ @m2.nat, @m2.list ], @rg.productive_non_terminals )
    assert_equal( Set[ @m2.nat, @m2.list ], @rg.reachable_non_terminals )
    assert_equal( <<EOF, @rg.reduce.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {list, nat}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    list -> [void, cons(nat,list)]
    nat -> [zero, s(nat)]
>
EOF
    assert_equal( <<EOF, @rg.normalize.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {list, nat}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    list -> [void, cons(nat,list)]
    nat -> [zero, s(nat)]
>
EOF
    assert_equal( <<EOF, @rg.dup.rename_non_terminals.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {nt_0, nt_1}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    nt_0 -> [void, cons(nt_1,nt_0)]
    nt_1 -> [zero, s(nt_1)]
>
EOF
    rg2 = @rg.dup.set_axiom(@m2.nat)
    assert_equal( Set[ @m2.nat, @m2.list ], rg2.productive_non_terminals )
    assert_equal( Set[ @m2.nat ], rg2.reachable_non_terminals )
    assert_equal( <<EOF, rg2.reduce.to_s )
<Grammar:
  axiom: nat
  non_terminals: <System: aphabet: {nat}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    nat -> [zero, s(nat)]
>
EOF

    assert_equal( <<EOF, @rg2.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {list, nat}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    list -> [void, cons(nat,list), cons(nat,cons(nat,list))]
    nat -> [zero, s(nat)]
>
EOF
    assert( @rg2.regular? )

    assert_equal( <<EOF, @rg2.reduce.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {list, nat}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    list -> [void, cons(nat,list), cons(nat,cons(nat,list))]
    nat -> [zero, s(nat)]
>
EOF

    assert_equal( <<EOF, @rg2.normalize.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {list, nat, new_nt_0}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    list -> [void, cons(nat,list), cons(nat,new_nt_0)]
    new_nt_0 -> [cons(nat,list)]
    nat -> [zero, s(nat)]
>
EOF
   assert_equal( <<EOF, @rg2.to_s )
<Grammar:
  axiom: list
  non_terminals: <System: aphabet: {list, nat}>
  terminals: <System: aphabet: {zero, void, s(), cons(,)}>
  rules:
    list -> [void, cons(nat,list), cons(nat,cons(nat,list))]
    nat -> [zero, s(nat)]
>
EOF

  end

  def test_grammar_automaton
      assert_equal( <<EOF, @rg.automaton.to_s )
<Automaton:
  system: <System: aphabet: {zero, void, s(), cons(,)}, states: {q_list, q_nat}>
  states: {q_list, q_nat}
  initial_states: {q_list}
  order: pre
  rules:
    q_list(void) -> [void]
    q_list(cons) -> [cons(q_nat,q_list)]
    q_nat(zero) -> [zero]
    q_nat(s) -> [s(q_nat)]
     -> [q_list]
>
EOF
    assert( @rg.automaton.deterministic? )
    d = @rg.derivation
    a = @rg.automaton
    r = a.run d.derivation
    assert(r.run)

    assert_equal( <<EOF, @rg2.automaton.to_s )
<Automaton:
  system: <System: aphabet: {zero, void, s(), cons(,)}, states: {q_list, q_nat, q_new_nt_0}>
  states: {q_list, q_nat, q_new_nt_0}
  initial_states: {q_list}
  order: pre
  rules:
    q_list(void) -> [void]
    q_list(cons) -> [cons(q_nat,q_list), cons(q_nat,q_new_nt_0)]
    q_new_nt_0(cons) -> [cons(q_nat,q_list)]
    q_nat(zero) -> [zero]
    q_nat(s) -> [s(q_nat)]
     -> [q_list]
>
EOF
    refute( @rg2.automaton.deterministic? )
    d2 = @rg2.derivation
    r = a.run d2.derivation
    assert(r.run)

  end

end
