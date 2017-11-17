require 'set'
require 'minitest/autorun'
require_relative '../lib/libtree'

class TestHomomorphism < Minitest::Test

  def setup
    mod = LibTree::define_system( alphabet: {g: 3, f: 2, a: 0, b: 0}, variables: [])
    @m = Module::new do
      extend mod
      class << self
        attr_reader :tree, :output_tree, :homomorphism
      end
      @tree = g(a,g(b,b,b),a)
      @output_tree = f(a,f(f(b,f(b,b)),a))
      @homomorphism = LibTree::Homomorphism::new(
         input_system: mod,
         output_system: mod,
         variables: [:x1, :x2, :x3],
         rules: { :g => f(:x1, f(:x2, :x3)) }
      )
    end
    @t = @m.tree
    @o_t = @m.output_tree
    @h = @m.homomorphism

    mod2 = LibTree::define_system( alphabet: {o: 2, a: 2, n: 1, one: 0, zero: 0}, variables: [])
    @m2 = Module::new do
      extend mod2
      class << self
        attr_reader :tree, :output_tree, :homomorphism
      end
      @tree = a(n(o(zero,one)),a(one,n(zero)))
      @output_tree = n(o(n(n(o(zero,one))),n(n(o(n(one),n(n(zero)))))))
      @homomorphism = LibTree::Homomorphism::new(
        input_system: mod2,
        output_system: mod2,
        variables: [:x1, :x2],
        rules: { :a => n(o(n(:x1), n(:x2))) }
      )
    end
    @t2 = @m2.tree
    @o_t2 = @m2.output_tree
    @h2 = @m2.homomorphism
  end

  def test_homomorphism
    assert_equal( @o_t, @h[@t] )
    assert_equal( @o_t2, @h2[@t2] )
  end

end
