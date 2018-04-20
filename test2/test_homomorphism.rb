require 'set'
require 'minitest/autorun'
require_relative '../lib2/libtree'

class TestHomomorphism < Minitest::Test

  def setup
    mod = LibTree::define_system( alphabet: {h: 3, g: 3, f: 2, a: 0, b: 0}, variables: [])
    @m = Module::new do
      extend mod
      class << self
        attr_reader :tree, :output_tree, :homomorphism
        attr_reader :output_tree_prime, :homomorphism_prime
        attr_reader :output_tree_ter, :homomorphism_ter
      end
      @tree = g(a,g(b,b,b),a)
      @output_tree = f(a,f(f(b,f(b,b)),a))
      @homomorphism = LibTree::Homomorphism::new(
         input_system: mod,
         output_system: mod,
         variables: [x1, x2, x3],
         rules: { :g => f(x1, f(x2, x3)) }
      )
      @output_tree_prime = f(a,a)
      @homomorphism_prime = LibTree::Homomorphism::new(
         input_system: mod,
         output_system: mod,
         variables: [x1, x2, x3],
         rules: { :g => f(x1, x1) }
      )
      @output_tree_ter = h(a,h(b,b,b),a)
      @homomorphism_ter = LibTree::Homomorphism::new(
         input_system: mod,
         output_system: mod,
         variables: [x1, x2, x3],
         rules: { :g => h(x1, x2, x3) }
      )
    end
    @t = @m.tree
    @o_t = @m.output_tree
    @h = @m.homomorphism
    @o_tp = @m.output_tree_prime
    @hp = @m.homomorphism_prime
    @o_tt = @m.output_tree_ter
    @ht = @m.homomorphism_ter

    mod2 = LibTree::define_system( alphabet: {o: 2, a: 2, n: 1, one: 0, zero: 0}, variables: [])
    @m2 = Module::new do
      extend mod2
      class << self
        attr_reader :tree, :output_tree, :homomorphism
        attr_reader :output_tree_prime, :homomorphism_prime
      end
      @tree = a(n(o(zero,one)),a(one,n(zero)))
      @output_tree = n(o(n(n(o(zero,one))),n(n(o(n(one),n(n(zero)))))))
      @homomorphism = LibTree::Homomorphism::new(
        input_system: mod2,
        output_system: mod2,
        variables: [x1, x2],
        rules: { :a => n(o(n(x1), n(x2))) }
      )
      @output_tree_prime = n(o(zero,one))
      @homomorphism_prime = LibTree::Homomorphism::new(
        input_system: mod2,
        output_system: mod2,
        variables: [x1, x2],
        rules: { :a => x1 }
      )
    end
    @t2 = @m2.tree
    @o_t2 = @m2.output_tree
    @h2 = @m2.homomorphism
    @o_t2p = @m2.output_tree_prime
    @h2p = @m2.homomorphism_prime
  end

  def test_homomorphism
    assert( @h.linear? ) 
    refute( @hp.linear? ) 
    assert( @ht.linear? ) 
    assert( @h2.linear? )
    assert( @h2p.linear? )

    assert( @h.epsilon_free? )
    assert( @hp.epsilon_free? )
    assert( @ht.epsilon_free? )
    assert( @h2.epsilon_free? )
    refute( @h2p.epsilon_free? )

    refute( @h.symbol_to_symbol? )
    assert( @hp.symbol_to_symbol? )
    assert( @ht.symbol_to_symbol? )
    refute( @h2.symbol_to_symbol? )
    refute( @h2p.symbol_to_symbol? )

    assert( @h.linear? ) 
    refute( @hp.linear? ) 
    assert( @ht.linear? ) 
    assert( @h2.linear? )
    assert( @h2p.linear? )

    assert( @h.complete? ) 
    refute( @hp.complete? ) 
    assert( @ht.complete? ) 
    assert( @h2.complete? )
    refute( @h2p.complete? )

    refute( @h.delabeling? ) 
    refute( @hp.delabeling? ) 
    assert( @ht.delabeling? ) 
    refute( @h2.delabeling? )
    refute( @h2p.delabeling? )

    refute( @h.relabeling? ) 
    refute( @hp.relabeling? ) 
    assert( @ht.relabeling? ) 
    refute( @h2.relabeling? )
    refute( @h2p.relabeling? )
    
    assert_equal( @o_t, @h[@t] )
    assert_equal( @o_tp, @hp[@t] )
    assert_equal( @o_tt, @ht[@t] )
    assert_equal( @o_t2, @h2[@t2] )
    assert_equal( @o_t2p, @h2p[@t2] )
  end

end
