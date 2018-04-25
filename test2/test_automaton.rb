require 'set'
require 'minitest/autorun'
require_relative '../lib2/libtree'

class TestAutomaton < Minitest::Test

  def setup
    mod = LibTree::define_system( alphabet: {o: 2, a: 2, n: 1, one: 0, zero: 0}, states: [:q0, :q1])
    @m = Module::new do
      extend mod
      class << self
        attr_reader :tree, :tree2, :automaton
      end
      @tree = a(n(o(zero,one)),o(one,n(zero)))
      @tree2 = a(n(n(o(zero,one))),o(one,n(zero)))
      @automaton = LibTree::Automaton::new( system: mod, states: [q0, q1], final_states: [q1],  rules: {
        zero => q0,
        one => q1,
        n(q0) => q1,
        n(q1) => q0,
        a(q0, q0) => q0,
        a(q1, q0) => q0,
        a(q0, q1) => q0,
        a(q1, q1) => q1,
        o(q0, q0) => q0,
        o(q1, q0) => q1,
        o(q0, q1) => q1,
        o(q1, q1) => q1
      } )

    end
    @t = @m.tree
    @t2 = @m.tree2
    @a = @m.automaton

    mod2 = LibTree::define_system( alphabet: {g: 1, a: 0, b: 0}, states: [:q, :q0, :q1])
    @m2 = Module::new do
      extend mod2
      class << self
        attr_reader :automaton
      end
      @automaton = LibTree::Automaton::new( system: mod2, states: [q0, q1, q], final_states: [q0], rules: {
        a => q0,
        g(q0) => q1,
        g(q1) => q0,
        g(q) => [q0, q1]
      } )
    end
    @a2 = @m2.automaton

    mod3 = LibTree::define_system( alphabet: {f: 2, g: 1, a: 0}, states: [:q, :qf, :qg])
    @m3 = Module::new do
      extend mod3
      class << self
        attr_reader :automaton
      end
      @automaton = LibTree::Automaton::new( system: mod3, states: [q, qg, qf], final_states: [qf], rules: {
        a => q,
        g(q) => [ q, qg ],
        g(qg) => qf,
        f(q,q) => q
      } )
    end
    @a3 = @m3.automaton

    mod4 = LibTree::define_system( alphabet: {cons: 2, s: 1, zero: 0, empt: 0}, states: [:qnat, :qlist, :qnelist])
    @m4 = Module::new do
      extend mod4
      class << self
        attr_reader :automaton
      end
      @automaton = LibTree::Automaton::new( system: mod4, states: [qnat, qlist, qnelist], final_states: [qnelist], rules: {
        zero => qnat,
        s(qnat) => qnat,
        empt => qlist,
        cons(qnat, qlist) => qnelist,
        qnelist => qlist
      } )
    end
    @a4 = @m4.automaton

    mod5 = LibTree::define_system( alphabet: {f: 1, g: 1, a: 0}, states: [:q0, :q1, :q2, :q3, :q4])
    @m5 = Module::new do
      extend mod5
      class << self
        attr_reader :automaton
      end
      @automaton = LibTree::Automaton::new( system: mod5, states: [q0, q1, q2, q3, q4], final_states: [q2, q3], rules: {
        a => q0,
        f(q0) => q1,
        g(q0) => q3,
        f(q1) => q1,
        g(q1) => q2,
        f(q2) => q4,
        g(q2) => q4,
        f(q3) => q4,
        g(q3) => q4,
        f(q4) => q4,
        g(q4) => q4
      } )
    end
    @a5 = @m5.automaton

    mod6 = LibTree::define_system( alphabet: {one: 1, zero: 1, nill: 0}, variables: [], states: [:q0, :q1, :q2])
    @m6 = Module::new do
      extend mod6
      class << self
        attr_reader :automaton, :automaton_bu, :tree_true, :tree_false
      end
      @automaton = LibTree::TopDownAutomaton::new( system: mod6, states: [q0, q1, q2], initial_states: [q0], rules: {
        q0(nill) => nill,
        q0(zero(:x)) => zero(q0),
        q0( one(:x)) =>  one(q1),
        q1(zero(:x)) => zero(q2),
        q1( one(:x)) =>  one(q0),
        q2(zero(:x)) => zero(q1),
        q2( one(:x)) =>  one(q2)
      } )
      @automaton_bu = LibTree::Automaton::new( system: mod6, states: [q0, q1, q2], final_states: [q0], rules: {
        nill => q0,
        zero(q0) => q0,
        one(q1) => q0,
        zero(q2) => q1,
        one(q0) => q1,
        zero(q1) => q2,
        one(q2) => q2
      } )
      @tree_true = one(one(zero(nill)))
      @tree_false = one(zero(nill))
    end
    @a6 = @m6.automaton
    @a6bu = @m6.automaton_bu
    @t6t = @m6.tree_true
    @t6f = @m6.tree_false
  end

  def test_top_down_automaton
    assert_equal( <<EOF, @a6.to_s )
<Automaton:
  system: <System: aphabet: {one(), zero(), nill}>
  states: {q0, q1, q2}
  initial_states: {q0}
  order: pre
  rules:
    q0(nill) -> nill
    q0(zero) -> zero(q0)
    q0(one) -> one(q1)
    q1(zero) -> zero(q2)
    q1(one) -> one(q0)
    q2(zero) -> zero(q1)
    q2(one) -> one(q2)
     -> q0
>
EOF
    r1 = @a6.run @t6t
    assert_equal( "q0(one(one(zero(nill))))", r1.tree.to_s )
    r1.move
    assert_equal( "one(q1(one(zero(nill))))", r1.tree.to_s )
    r1.move
    assert_equal( "one(one(q0(zero(nill))))", r1.tree.to_s )
    r1.move
    assert_equal( "one(one(zero(q0(nill))))", r1.tree.to_s )
    r1.move
    assert_equal( "one(one(zero(nill)))", r1.tree.to_s )
    assert_raises( StopIteration ) { r1.move }
    r1 = @a6.run @t6t
    assert( r1.run )
    assert_equal( "one(one(zero(nill)))", r1.tree.to_s )

    r2 = @a6.run @t6f
    assert_equal( "q0(one(zero(nill)))", r2.tree.to_s )
    r2.move
    assert_equal( "one(q1(zero(nill)))", r2.tree.to_s )
    r2.move
    assert_equal( "one(zero(q2(nill)))", r2.tree.to_s )
    assert_raises( StopIteration ) { r2.move }
    r2 = @a6.run @t6f
    refute( r2.run )
    assert_equal( "one(zero(nill))", r2.tree.to_s )

    r3 = @a6bu.run @t6t
    assert( r3.run )
    r4 = @a6bu.run @t6f
    refute( r4.run )
  end

  def test_bottom_up_to_top_down
    assert_equal(@a6bu.to_top_down_automaton.to_s, @a6.to_s)
    r1 = @a6bu.to_top_down_automaton.run @t6t
    assert( r1.run )
    r2 = @a6bu.to_top_down_automaton.run @t6f
    refute( r2.run )
  end

  def test_top_down_to_bottom_up
    assert_equal(@a6.to_bottom_up_automaton.to_s, @a6bu.to_s)
    r1 = @a6.to_bottom_up_automaton.run @t6t
    assert( r1.run )
    r2 = @a6.to_bottom_up_automaton.run @t6f
    refute( r2.run )
  end

  def test_epsilon_rules
    assert_equal( <<EOF, @a4.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}>
  states: {qnat, qlist, qnelist}
  final_states: {qnelist}
  order: post
  rules:
    zero -> qnat
    s(qnat) -> qnat
    empt -> qlist
    cons(qnat,qlist) -> qnelist
    qnelist -> qlist
>
EOF
    assert(@a4.epsilon_rules?)
    assert_equal( 1, @a4.epsilon_rules.size)
    assert_equal( [LibTree::BaseAutomaton::RuleSet::Rule::new(nil, state: @m4.qnelist), [@m4.qlist]], @a4.epsilon_rules.first)
    refute(@a4.deterministic?)
    assert_equal( <<EOF, @a4.remove_epsilon_rules.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}>
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
  system: <System: aphabet: {cons(,), s(), zero, empt}>
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
    a4td = @a4.to_top_down_automaton
    assert_equal( <<EOF, a4td.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}>
  states: {qnat, qlist, qnelist}
  initial_states: {qnelist}
  order: pre
  rules:
    qnat(zero) -> zero
    qnat(s) -> s(qnat)
    qlist(empt) -> empt
    qnelist(cons) -> cons(qnat,qlist)
    qlist -> qnelist
     -> qnelist
>
EOF
    assert( a4td.epsilon_rules? )
    assert_equal( 1 , a4td.epsilon_rules.size )
    assert_equal( [LibTree::BaseAutomaton::RuleSet::Rule::new(nil, state: @m4.qlist), [@m4.qnelist]], a4td.epsilon_rules.first)
    assert_equal( @a4.remove_epsilon_rules.to_top_down_automaton.to_s, a4td.remove_epsilon_rules.to_s )
  end

  def test_automaton
    k, v = @a.rules.first
    assert_equal( @m.zero, k )
    assert_equal( [@m.q0], v )
    k, v = @a.rules.reverse_each.first
    assert_equal( LibTree::Automaton::RuleSet::compute_rule(@m.o(@m.q1,@m.q1)), k )
    assert_equal( [@m.q1], v )
    assert_equal( 44, @a.size )
    assert( @a.deterministic? )
    assert( @a.complete? )
    assert( @a.reduced? )
    refute( @a.epsilon_rules? )
    assert_equal( @a.complete, @a )
    assert( 17, @a2.size )
    refute( @a2.deterministic? )
    refute( @a2.complete? )
    assert( @a2.complete.complete? )
    refute_equal( @a2.complete, @a2 )
    refute( @a2.reduced? )
    assert_equal( Set[@m.q0, @m.q1], @a2.reduce.states )
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
  system: <System: aphabet: {f(), g(), a}>
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
  system: <System: aphabet: {o(,), a(,), n(), one, zero}>
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
  system: <System: aphabet: {o(,), a(,), n(), one, zero}>
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
  system: <System: aphabet: {o(,), a(,), n(), one, zero}>
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
  system: <System: aphabet: {f(,), g(), a}>
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
  system: <System: aphabet: {f(,), g(), a}>
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
  system: <System: aphabet: {f(,), g(), a}>
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
    r = @a.run @t
    r.move
    assert_equal( "a(n(o(q0(zero),one)),o(one,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(n(o(q0(zero),q1(one))),o(one,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(n(q1(o(zero,one))),o(one,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(n(o(zero,one))),o(one,n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(n(o(zero,one))),o(q1(one),n(zero)))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(n(o(zero,one))),o(q1(one),n(q0(zero))))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(n(o(zero,one))),o(q1(one),q1(n(zero))))" , r.tree.to_s)
    r.move
    assert_equal( "a(q0(n(o(zero,one))),q1(o(one,n(zero))))" , r.tree.to_s)
    r.move
    assert_equal( "q0(a(n(o(zero,one)),o(one,n(zero))))" , r.tree.to_s)
    assert_raises( StopIteration ) {
      r.move
    }
    refute(r.successful?)
  end

  def test_run
    r = @a.run @t
    refute(r.run)
    assert_equal( "a(n(o(zero,one)),o(one,n(zero)))" , r.tree.to_s)
    refute(r.successful?)
    r2 = @a.run @t2
    assert(r2.run)
    assert_equal( "a(n(n(o(zero,one))),o(one,n(zero)))" , r2.tree.to_s)
    assert(r2.successful?)
  end

  def test_non_deterministic_td_automaton
    atd = @a.to_top_down_automaton
    assert_equal( <<EOF, atd.to_s )
<Automaton:
  system: <System: aphabet: {o(,), a(,), n(), one, zero}>
  states: {q0, q1}
  initial_states: {q1}
  order: pre
  rules:
    q0(zero) -> zero
    q1(one) -> one
    q1(n) -> n(q0)
    q0(n) -> n(q1)
    q0(a) -> [a(q0,q0), a(q1,q0), a(q0,q1)]
    q1(a) -> a(q1,q1)
    q0(o) -> o(q0,q0)
    q1(o) -> [o(q1,q0), o(q0,q1), o(q1,q1)]
     -> q1
>
EOF
    r = atd.run @t
    refute(r.run)
    refute(r.successful?)
    r2 = atd.run @t2
    assert(r2.run)
    assert(r2.successful?)
  end

end
