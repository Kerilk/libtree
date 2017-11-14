require 'set'
require 'minitest/autorun'
require_relative '../lib/libtree'

class TestLibTree < Minitest::Test

  def setup
    mod = LibTree::define_system( alphabet: {f: 3, g: 2, h: 1, a: 0, b: 0}, variables: [:x, :y])
    @m = Module::new do
      extend mod
      class << self
        attr_reader :t, :t_p, :t_r, :t_s, :t_subst
      end
      @t = f(g(a,b),a,h(b))
      @t_s = g(a,b)
      @t_r = f(g(a,b),a,a)
      @t_p = f(g(x,y),a,g(x,y))

      @t_subst = f(x,x,y)

    end
    @t_p = @m.t_p
    @t_r = @m.t_r
    @t_s = @m.t_s
    @t = @m.t
    @t_subst = @m.t_subst
  end

  def test_height
    assert_equal(3, @t.height)
    assert_equal(2, @t_p.height)
  end

  def test_size
    assert_equal(7, @t.size)
    assert_equal(4, @t_p.size)
  end

  def test_positions
    assert_equal( Set[[0], [0,0], [0,1], [1], [2], [2,0]], @t.positions)
    assert_equal( Set[[0], [0,0], [0,1], [1], [2], [2,0], [2,1]], @t_p.positions)
  end

  def test_frontier_positions
    assert_equal( Set[ [0,0], [0,1], [1], [2,0]], @t.frontier_positions)
    assert_equal( Set[ [0,0], [0,1], [1], [2,0], [2,1]], @t_p.frontier_positions)
  end

  def test_variable_positions
    assert_equal( Set[], @t.variable_positions)
    assert_equal( Set[ [0,0], [0,1], [2,0], [2,1]], @t_p.variable_positions)
  end

  def test_bracket
    assert_equal( :b, @t[0,1] )
    assert_equal( :h, @t[2] )
    assert_equal( :x, @t_p[2,0] )
    assert_equal( :f, @t[] )
  end

  def test_dup
    t = @t.dup
    assert_equal(@t, t)
  end

  def test_replace
    t = @t.dup
    assert_equal( @m.a, t[2]=@m.a )
    assert_equal( @t_r, t )
  end

  def test_subterm
    assert_equal( @t_s, @t|[0] )
    assert_equal( @m.x, @t_p|[2, 0] )
    refute_equal( @m.x, @t|[2, 0] )
  end

  def test_compare
    assert( @t > @t_s )
    assert( @t >= @t_s )
    refute( @t_p >= @t_s )
    assert( @t_s < @t )
    assert( @t_s <= @t )
    assert( @t <= @t )
    assert( @t >= @t )
    refute( @t < @t )
    refute( @t > @t )
  end

  def test_linear
    assert( @t.linear? )
    refute( @t_p.linear? )
    assert( @m.x.linear? )
  end

  def test_ground_term
    assert( @t.ground_term? )
    refute( @t_p.ground_term? )
  end

  def test_substitution
    s1 = @m.substitution(x: @m.a, y: @m.g(@m.b, @m.b))
    assert( s1.ground? )
    assert_equal( Set[:x, :y], s1.domain )
    s2 = @m.substitution(x: @m.y, y: @m.b)
    assert_equal( Set[:x, :y], s2.domain )
    refute( s2.ground? )
    assert_equal(@m.f(@m.a, @m.a, @m.g(@m.b, @m.b)), @t_subst * s1)
    assert_equal(@m.f(@m.a, @m.a, @m.g(@m.b, @m.b)), s1[@t_subst])
    assert_equal(@m.f(@m.y, @m.y, @m.b), @t_subst * s2)
    assert_equal(@m.f(@m.y, @m.y, @m.b), s2[@t_subst])
    assert_equal(@m.y, s2[@m.x])
  end

  def test_each_post_order
    s1 = ""
    @t.each_post_order { |e| s1 << e.symbol.to_s }
    assert_equal("abgabhf", s1)
    s2 = ""
    @t_p.each_post_order { |e| s2 << e.symbol.to_s }
    assert_equal("xygaxygf", s2)
    en = @t.each_post_order.lazy
    assert_equal(@m.a, en.next)
    assert_equal(@m.b, en.next)
  end

  def test_each_pre_order
    s1 = ""
    @t.each_pre_order { |e| s1 << e.symbol.to_s }
    assert_equal("fgabahb", s1)
    s2 = ""
    @t_p.each_pre_order { |e| s2 << e.symbol.to_s }
    assert_equal("fgxyagxy", s2)
  end

  def test_each
    s1 = ""
    @t.each { |e| s1 << e.symbol.to_s }
    assert_equal("abgabhf", s1)
    s2 = ""
    @t_p.each(:pre) { |e| s2 << e.symbol.to_s }
    assert_equal("fgxyagxy", s2)
  end

end
