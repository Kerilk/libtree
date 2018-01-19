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

end
