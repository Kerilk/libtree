require 'set'
require 'minitest/autorun'
require_relative '../lib2/libtree'

class TestCapture < Minitest::Test

  def setup
    non_terminals = LibTree::define_system( alphabet: { list: 0, nat: 0 })
    mod1 = LibTree::define_system( alphabet: {cons: 2, s: 1, zero: 0, empt: 0}, states: [:qnat, :qlist, :qnelist])
    @m1 = Module::new do
      extend mod1
      extend non_terminals
      class << self
        attr_reader :automaton
        attr_reader :automaton_epsilon
        attr_reader :top_down_automaton
        attr_reader :tree
        attr_reader :regular_expression1
        attr_reader :regular_expression2
      end
      @automaton = LibTree::Automaton::new( system: mod1, states: [qnat, qlist, qnelist], final_states: [qnelist], rules: {
        zero => qnat,
        s(qnat) => qnat,
        empt => qlist,
        cons(qnat, qlist)   => qnelist(capture: {0=>:first_nat}),
        cons(qnat, qnelist) => qnelist(capture: {0=>:other_nat})
      } )
      @automaton_epsilon = LibTree::Automaton::new( system: mod1, states: [qnat, qlist, qnelist], final_states: [qnelist], rules: {
        zero => qnat,
        s(qnat) => qnat,
        empt => qlist,
        cons(qnat, qlist)   => qnelist(capture: {0=>:nat}),
        qnelist => qlist
      } )
      @tree = cons(s(s(zero)), cons(s(zero), cons(s(s(s(zero))), empt )))
      @top_down_automaton = LibTree::TopDownAutomaton::new( system: mod1, states: [qnat, qlist, qnelist], initial_states: [qnelist], rules: {
        qnat(zero) => zero,
        qnat(s(:x0)) => s(qnat),
        qlist(empt) => empt,
        qnelist(cons(:x0,:x1)) => [
          cons(qnat, qlist, capture: {0=>:first_nat}),
          cons(qnat, qnelist, capture: {0=>:other_nat})
        ]
      } )
      @regular_expression1 = cons((s(sq)**:* / zero)>>:capt_nat, sq)**:* / empt
      @regular_expression2 = empt + cons((s(sq)**:* / zero)>>:capt_nat, sq)**:* / empt
    end
    @a1 = @m1.automaton
    @t1 = @m1.tree
    @a2 = @m1.top_down_automaton
    @re1 = @m1.regular_expression1
    @a3 = @m1.automaton_epsilon
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
    r = @a1.run(@t1)
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
    r = @a1.to_grammar.bottom_up_automaton.run(@t1)
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
    r = @a2.run(@t1)
    r.run
    assert_equal( { 
        :other_nat => [ @m1.s(@m1.s(@m1.zero)), @m1.s(@m1.zero) ],
        :first_nat => [ @m1.s(@m1.s(@m1.s(@m1.zero))) ]
      },
      r.matches
    )
    assert_equal( @a1.to_s, @a2.to_bottom_up_automaton.to_s )
    assert_equal( @a2.to_grammar.to_s, @a1.to_grammar.to_s )
    r = @a2.to_grammar.top_down_automaton.run(@t1)
    r.run
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
      r = @a2.run(t)
      r.run
      assert_equal(r.matches, d.matches)
    }
  end


  def test_capture_grammar
    g = @a2.to_grammar
    assert_equal( <<EOF, g.to_s )
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
    assert_equal( <<EOF, g.dup.rename_non_terminals.to_s )
<Grammar:
  axiom: nt_2
  non_terminals: <System: aphabet: {nt_0, nt_1, nt_2}>
  terminals: <System: aphabet: {cons(,), s(), zero, empt}>
  rules:
    nt_0 -> [zero, s(nt_0)]
    nt_1 -> empt
    nt_2 -> [cons(nt_0,nt_1)({0=>:first_nat}), cons(nt_0,nt_2)({0=>:other_nat})]
>
EOF
  end

  def test_bottom_up_capture_with_epsilon
    assert_equal( <<EOF, @a3.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}>
  states: {qnat, qlist, qnelist}
  final_states: {qnelist}
  order: post
  rules:
    zero -> qnat
    s(qnat) -> qnat
    empt -> qlist
    cons(qnat,qlist) -> qnelist({0=>:nat})
    qnelist -> qlist
>
EOF
    assert_equal( <<EOF, @a3.remove_epsilon_rules.to_s )
<Automaton:
  system: <System: aphabet: {cons(,), s(), zero, empt}>
  states: {qnat, qlist, qnelist}
  final_states: {qnelist}
  order: post
  rules:
    zero -> qnat
    s(qnat) -> qnat
    empt -> qlist
    cons(qnat,qlist) -> [qnelist({0=>:nat}), qlist({0=>:nat})]
>
EOF
  end

#  def test_capture_regular_expression
#    g = @re1.to_grammar
#    puts g.to_s
#    a = g.bottom_up_automaton
#    puts a.to_s
#  end

end
