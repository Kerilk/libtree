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

    mod3 = LibTree::define_system( alphabet: {f: 2, g: 1, a: 0}, variables: [])
    @m3 = Module::new do
      extend mod3
      class << self
        attr_reader :automaton
      end
      @automaton = LibTree::Automaton::new( system: mod3, states: [:q, :qg, :qf], final_states: [:qf], rules: {
        a => :q,
        g(:q) => [ :q, :qg ],
        g(:qg) => :qf,
        f(:q,:q) => :q
      } )
    end
    @a3 = @m3.automaton

    mod4 = LibTree::define_system( alphabet: {cons: 2, s: 1, zero: 0, empt: 0}, variables: [])
    @m4 = Module::new do
      extend mod4
      class << self
        attr_reader :automaton
      end
      @automaton = LibTree::Automaton::new( system: mod4, states: [:qnat, :qlist, :qnelist], final_states: [:qnelist], rules: {
        zero => :qnat,
        s(:qnat) => :qnat,
        empt => :qlist,
        cons(:qnat, :qlist) => :qnelist,
        :qnelist => :qlist
      } )
    end
    @a4 = @m4.automaton

    mod5 = LibTree::define_system( alphabet: {f: 1, g: 1, a: 0}, variables: [])
    @m5 = Module::new do
      extend mod5
      class << self
        attr_reader :automaton
      end
      @automaton = LibTree::Automaton::new( system: mod5, states: [:q0, :q1, :q2, :q3, :q4], final_states: [:q2, :q3], rules: {
        a => :q0,
        f(:q0) => :q1,
        g(:q0) => :q3,
        f(:q1) => :q1,
        g(:q1) => :q2,
        f(:q2) => :q4,
        g(:q2) => :q4,
        f(:q3) => :q4,
        g(:q3) => :q4,
        f(:q4) => :q4,
        g(:q4) => :q4
      } )
    end
    @a5 = @m5.automaton
  end

  def test_epsilon_rules
    assert(@a4.epsilon_rules?)
    assert_equal( 1, @a4.epsilon_rules.size)
    assert_equal( [:qnelist, :qlist], @a4.epsilon_rules.first)
    refute(@a4.deterministic?)
    assert_equal( <<EOF, @a4.remove_epsilon_rules.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}, variables: {}>
  states: {qnat, qlist, qnelist}
  final_states: {qnelist}
  order: post
  rules:
    zero -> qnat
    s(qnat) -> qnat
    empt -> qlist
    cons(qnat,qlist) -> [qnelist, qlist]
>
EOF
    assert_equal( <<EOF,  @a4.determinize.rename_states.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}, variables: {}>
  states: {qr0, qr1, qr2}
  final_states: {qr2}
  order: post
  rules:
    zero -> qr0
    empt -> qr1
    cons(qr0,qr1) -> qr2
    s(qr0) -> qr0
    cons(qr0,qr2) -> qr2
>
EOF
  end

  def test_automaton
    k, v = @a.rules.first
    assert_equal( @m.zero, k )
    assert_equal( :q0, v )
    k, v = @a.rules.reverse_each.first
    assert_equal( LibTree::Automaton::RuleSet::compute_rule(@m.o(:q1,:q1)), k )
    assert_equal( :q1, v )
    assert( @a.deterministic? )
    assert( @a.complete? )
    assert( @a.reduced? )
    refute( @a.epsilon_rules? )
    assert_equal( @a.complete, @a )
    refute( @a2.deterministic? )
    refute( @a2.complete? )
    assert( @a2.complete.complete? )
    refute_equal( @a2.complete, @a2 )
    refute( @a2.reduced? )
    assert_equal( Set[:q0, :q1], @a2.reduce.states )
    assert_equal( 3, @a2.reduce.rules.size )
    refute( @a2.epsilon_rules? )
  end

  def test_determinize
    refute( @a3.deterministic? )
    d = @a3.determinize
    assert( d.deterministic? )
    assert_equal( Set[ Set[:q], Set[:q, :qg], Set[:q, :qg, :qf] ], d.states )
    assert_equal( Set[ Set[:q, :qg, :qf] ], d.final_states )
    assert_equal( 13, d.rules.size )
  end

  def test_minimize
    assert( @a5.deterministic? )
    assert( @a5.complete? )
    assert( @a5.reduced? )
    assert_equal( <<EOF, @a5.minimize.to_s )
<Automaton:
  system: <System: aphabet: {f(), g(), a}, variables: {}>
  states: {{q3, q2}, {q0, q1}, {q4}}
  final_states: {{q3, q2}}
  order: post
  rules:
    f({q3, q2}) -> {q4}
    f({q0, q1}) -> {q0, q1}
    f({q4}) -> {q4}
    g({q3, q2}) -> {q4}
    g({q0, q1}) -> {q3, q2}
    g({q4}) -> {q4}
    a -> {q0, q1}
>
EOF
  end

  def test_union
    new_a = @a | @a
    assert_equal( <<EOF,  new_a.minimize.rename_states.to_s)
<Automaton:
  system: <System: aphabet: {o(,), a(,), n(), one, zero}, variables: {}>
  states: {qr0, qr1}
  final_states: {qr0}
  order: post
  rules:
    o(qr0,qr0) -> qr0
    o(qr0,qr1) -> qr0
    o(qr1,qr0) -> qr0
    o(qr1,qr1) -> qr1
    a(qr0,qr0) -> qr0
    a(qr0,qr1) -> qr1
    a(qr1,qr0) -> qr1
    a(qr1,qr1) -> qr1
    n(qr0) -> qr1
    n(qr1) -> qr0
    one -> qr0
    zero -> qr1
>
EOF
  end

  def test_complement
    new_a = ~@a
    assert_equal( <<EOF, new_a.to_s)
<Automaton:
  system: <System: aphabet: {o(,), a(,), n(), one, zero}, variables: {}>
  states: {q0, q1}
  final_states: {q0}
  order: post
  rules:
    zero -> q0
    one -> q1
    n(q0) -> q1
    n(q1) -> q0
    a(q0,q0) -> q0
    a(q1,q0) -> q0
    a(q0,q1) -> q0
    a(q1,q1) -> q1
    o(q0,q0) -> q0
    o(q1,q0) -> q1
    o(q0,q1) -> q1
    o(q1,q1) -> q1
>
EOF
  end

  def test_intersection
    new_a = @a & @a
    assert_equal( <<EOF,  new_a.minimize.rename_states.to_s)
<Automaton:
  system: <System: aphabet: {o(,), a(,), n(), one, zero}, variables: {}>
  states: {qr0, qr1}
  final_states: {qr0}
  order: post
  rules:
    o(qr0,qr0) -> qr0
    o(qr0,qr1) -> qr0
    o(qr1,qr0) -> qr0
    o(qr1,qr1) -> qr1
    a(qr0,qr0) -> qr0
    a(qr0,qr1) -> qr1
    a(qr1,qr0) -> qr1
    a(qr1,qr1) -> qr1
    n(qr0) -> qr1
    n(qr1) -> qr0
    one -> qr0
    zero -> qr1
>
EOF
  end

  def test_to_s
    assert_equal( <<EOF, @a3.to_s )
<Automaton:
  system: <System: aphabet: {f(,), g(), a}, variables: {}>
  states: {q, qg, qf}
  final_states: {qf}
  order: post
  rules:
    a -> q
    g(q) -> [q, qg]
    g(qg) -> qf
    f(q,q) -> q
>
EOF
    assert_equal( <<EOF, @a3.determinize.to_s )
<Automaton:
  system: <System: aphabet: {f(,), g(), a}, variables: {}>
  states: {{q}, {q, qg}, {q, qg, qf}}
  final_states: {{q, qg, qf}}
  order: post
  rules:
    a -> {q}
    f({q},{q}) -> {q}
    g({q}) -> {q, qg}
    f({q},{q, qg}) -> {q}
    f({q, qg},{q}) -> {q}
    f({q, qg},{q, qg}) -> {q}
    g({q, qg}) -> {q, qg, qf}
    f({q},{q, qg, qf}) -> {q}
    f({q, qg},{q, qg, qf}) -> {q}
    f({q, qg, qf},{q}) -> {q}
    f({q, qg, qf},{q, qg}) -> {q}
    f({q, qg, qf},{q, qg, qf}) -> {q}
    g({q, qg, qf}) -> {q, qg, qf}
>
EOF
    assert_equal( <<EOF, @a3.determinize.rename_states.to_s )
<Automaton:
  system: <System: aphabet: {f(,), g(), a}, variables: {}>
  states: {qr0, qr1, qr2}
  final_states: {qr2}
  order: post
  rules:
    a -> qr0
    f(qr0,qr0) -> qr0
    g(qr0) -> qr1
    f(qr0,qr1) -> qr0
    f(qr1,qr0) -> qr0
    f(qr1,qr1) -> qr0
    g(qr1) -> qr2
    f(qr0,qr2) -> qr0
    f(qr1,qr2) -> qr0
    f(qr2,qr0) -> qr0
    f(qr2,qr1) -> qr0
    f(qr2,qr2) -> qr0
    g(qr2) -> qr2
>
EOF
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
