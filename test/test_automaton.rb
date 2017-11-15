require 'set'
require 'minitest/autorun'
require_relative '../lib/libtree'

class TestAutomaton < Minitest::Test

  def setup
    mod = LibTree::define_system( alphabet: {o: 2, a: 2, n: 1, one: 0, zero: 0}, variables: [])
    @m = Module::new do
      extend mod
      class << self
        attr_reader :tree, :tree2, :automaton
      end
      @tree = a(n(o(zero,one)),o(one,n(zero)))
      @tree2 = a(n(n(o(zero,one))),o(one,n(zero)))
      @automaton = LibTree::Automaton::new( system: mod, states: [:q0, :q1], final_states: [:q1],  rules: {
        zero => :q0,
        one => :q1,
        n(:q0) => :q1,
        n(:q1) => :q0,
        a(:q0, :q0) => :q0,
        a(:q1, :q0) => :q0,
        a(:q0, :q1) => :q0,
        a(:q1, :q1) => :q1,
        o(:q0, :q0) => :q0,
        o(:q1, :q0) => :q1,
        o(:q0, :q1) => :q1,
        o(:q1, :q1) => :q1
      } )

    end
    @t = @m.tree
    @t2 = @m.tree2
    @a = @m.automaton
    mod2 = LibTree::define_system( alphabet: {g: 1, a: 0, b: 0}, variables: [])
    @m2 = Module::new do
      extend mod2
      class << self
        attr_reader :automaton
      end
      @automaton = LibTree::Automaton::new( system: mod2, states: [:q0, :q1, :q], final_states: [:q0], rules: {
        a => :q0,
        g(:q0) => :q1,
        g(:q1) => :q0,
        g(:q) => [:q0, :q1]
      } )
    end
    @a2 = @m2.automaton
  end

  def test_automaton
    k, v = @a.rules.first
    assert_equal( @m.zero, k )
    assert_equal( :q0, v )
    k, v = @a.rules.reverse_each.first
    assert_equal( @m.o(:q1,:q1), k )
    assert_equal( :q1, v )
    assert( @a.deterministic? )
    assert( @a.complete? )
    assert( @a.reduced? )
    assert_equal( @a.complete, @a )
    refute( @a2.deterministic? )
    refute( @a2.complete? )
    assert( @a2.complete.complete? )
    refute_equal( @a2.complete, @a2 )
    refute( @a2.reduced? )
    assert_equal( Set[:q0, :q1], @a2.reduce.states )
    assert_equal( 3, @a2.reduce.rules.size )
  end

  def test_move
    r = LibTree::Run::new(@a, @t)
    r.move
    assert_equal( "a(n(o(q0,one)),o(one,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(n(o(q0,q1)),o(one,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(n(q1(q0,q1)),o(one,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(q1(q0,q1)),o(one,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(q1(q0,q1)),o(q1,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(q1(q0,q1)),o(q1,n(q0)))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(q1(q0,q1)),o(q1,q1(q0)))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(q1(q0,q1)),q1(q1,q1(q0)))" , r.tree.to_s)
    r.move
    assert_equal( "q0(q0(q1(q0,q1)),q1(q1,q1(q0)))" , r.tree.to_s)
    assert_raises( StopIteration ) {
      r.move
    }
    refute(r.successful?)

  end

  def test_run
    r = LibTree::Run::new(@a, @t)
    refute(r.run)
    assert_equal( "q0(q0(q1(q0,q1)),q1(q1,q1(q0)))" , r.tree.to_s)
    refute(r.successful?)
    r2 = LibTree::Run::new(@a, @t2)
    assert(r2.run)
    assert_equal( "q1(q1(q0(q1(q0,q1))),q1(q1,q1(q0)))" , r2.tree.to_s)
    assert(r2.successful?)
  end

end
