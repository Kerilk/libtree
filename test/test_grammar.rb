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
    assert_equal( Set[ @m2.nat, @m2.list ], @rg.dup.set_axiom(@m2.nat).productive_non_terminals )
    assert_equal( Set[ @m2.nat ], @rg.dup.set_axiom(@m2.nat).reachable_non_terminals )
  end

end