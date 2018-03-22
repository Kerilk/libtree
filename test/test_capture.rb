require 'set'
require 'minitest/autorun'
require_relative '../lib/libtree'

class TestCapture < Minitest::Test

  def setup
    mod1 = LibTree::define_system( alphabet: {cons: 2, s: 1, zero: 0, empt: 0}, states: [:qnat, :qlist, :qnelist])
    @m1 = Module::new do
      extend mod1
      class << self
        attr_reader :automaton
        attr_reader :top_down_automaton
        attr_reader :tree
      end
      @automaton = LibTree::Automaton::new( system: mod1, states: [:qnat, :qlist, :qnelist], final_states: [:qnelist], rules: {
        zero => qnat,
        s(qnat) => qnat,
        empt => qlist,
        cons(qnat, qlist)   => LibTree::CaptureState::new(qnelist, {0=>:first_nat}),
        cons(qnat, qnelist) => LibTree::CaptureState::new(qnelist, {0=>:other_nat})
      } )
      @tree = cons(s(s(zero)), cons(s(zero), cons(s(s(s(zero))), empt )))
      @top_down_automaton = LibTree::TopDownAutomaton::new( system: mod1, states: [:qnat, :qlist, :qnelist], initial_states: [:qnelist], rules: {
        qnat(zero) => zero,
        qnat(s(:x0)) => s(qnat),
        qlist(empt) => empt,
        qnelist(cons(:x0,:x1)) => [
          LibTree::CaptureState::new(cons(qnat, qlist),   {0=>:first_nat}),
          LibTree::CaptureState::new(cons(qnat, qnelist), {0=>:other_nat})
        ]
      } )
    end
    @a1 = @m1.automaton
    @t1 = @m1.tree
    @a2 = @m1.top_down_automaton
  end

  def test_capture_bu_automaton
    assert_equal( <<EOF, @a1.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}>
  states: {qnat, qlist, qnelist}
  final_states: {qnelist}
  order: post
  rules:
    zero -> qnat
    s(qnat) -> qnat
    empt -> qlist
    cons(qnat,qlist) -> qnelist({0=>:first_nat})
    cons(qnat,qnelist) -> qnelist({0=>:other_nat})
>
EOF
    r = @a1.run(@t1, rewrite: false)
    assert(r.run)
    assert_equal( { 
        :other_nat => [ @m1.s(@m1.zero), @m1.s(@m1.s(@m1.zero)) ],
        :first_nat => [ @m1.s(@m1.s(@m1.s(@m1.zero))) ]
      },
      r.matches
    )
    assert_equal( @a2.to_s, @a1.to_top_down_automaton.to_s )
    assert_equal( <<EOF, @a1.dup.rename_states.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}>
  states: {qr0, qr1, qr2}
  final_states: {qr2}
  order: post
  rules:
    zero -> qr0
    s(qr0) -> qr0
    empt -> qr1
    cons(qr0,qr1) -> qr2({0=>:first_nat})
    cons(qr0,qr2) -> qr2({0=>:other_nat})
>
EOF
    assert_equal( <<EOF, @a1.to_grammar.to_s )
<Grammar:
  axiom: qnelist
  non_terminals: <System: aphabet: {qnat, qlist, qnelist}>
  terminals: <System: aphabet: {cons(,), s(), zero, empt}>
  rules:
    qnat -> [zero, s(qnat)]
    qlist -> empt
    qnelist -> [cons(qnat,qlist)({0=>:first_nat}), cons(qnat,qnelist)({0=>:other_nat})]
>
EOF
    r = @a1.to_grammar.bottom_up_automaton.run(@t1, rewrite: false)
    assert(r.run)
    assert_equal( { 
        :other_nat => [ @m1.s(@m1.zero), @m1.s(@m1.s(@m1.zero)) ],
        :first_nat => [ @m1.s(@m1.s(@m1.s(@m1.zero))) ]
      },
      r.matches
    )
  end

  def test_capture_td_automaton
    assert_equal( <<EOF, @a2.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}>
  states: {qnat, qlist, qnelist}
  initial_states: {qnelist}
  order: pre
  rules:
    qnat(zero) -> zero
    qnat(s) -> s(qnat)
    qlist(empt) -> empt
    qnelist(cons) -> [cons(qnat,qlist)({0=>:first_nat}), cons(qnat,qnelist)({0=>:other_nat})]
     -> qnelist
>
EOF
    r = nil
    loop do
      r = @a2.run(@t1)
      break if r.run
    end
    assert_equal( { 
        :other_nat => [ @m1.s(@m1.s(@m1.zero)), @m1.s(@m1.zero) ],
        :first_nat => [ @m1.s(@m1.s(@m1.s(@m1.zero))) ]
      },
      r.matches
    )
    assert_equal( @a1.to_s, @a2.to_bottom_up_automaton.to_s )
    assert_equal( <<EOF, @a2.to_grammar.to_s )
<Grammar:
  axiom: qnelist
  non_terminals: <System: aphabet: {qnat, qlist, qnelist}>
  terminals: <System: aphabet: {cons(,), s(), zero, empt}>
  rules:
    qnat -> [zero, s(qnat)]
    qlist -> empt
    qnelist -> [cons(qnat,qlist)({0=>:first_nat}), cons(qnat,qnelist)({0=>:other_nat})]
>
EOF
    assert_equal( @a2.to_grammar.to_s, @a1.to_grammar.to_s )
    r = nil
    loop do
      r = @a2.to_grammar.top_down_automaton.run(@t1)
      break if r.run
    end
    assert_equal( { 
        :other_nat => [ @m1.s(@m1.s(@m1.zero)), @m1.s(@m1.zero) ],
        :first_nat => [ @m1.s(@m1.s(@m1.s(@m1.zero))) ]
      },
      r.matches
    )
    g = @a2.to_grammar
    10.times {
      d = g.derivation
      t = d.derivation
      loop do
        r = @a2.run(t, rewrite: false)
        break if r.run
      end
      assert_equal(r.matches, d.matches)
    }
  end

end
