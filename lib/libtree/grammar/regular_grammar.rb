module LibTree

  class RegularGrammar < Grammar
    using RefineSet

    def initialize(*args)
      super
      raise "Grammar is not regular!" unless self.regular?
    end

    def productive_non_terminals
      productive = Set[]
      loop do
        previously_productive = productive.dup
        @rules.each { |k, v|
          v = [v] unless v.kind_of?(Array)
          v.each { |p|
            prod = true
            p.each { |c|
              prod = false unless previously_productive.include?( c ) || (@terminals.alphabet.include?(c.symbol) && @terminals.alphabet[c.symbol] == c.arity)
            }
            productive.add(k) if prod
          }
        }
        break if previously_productive == productive
      end
      productive
    end

    def reachable_non_terminals
      reachable = Set[@axiom]
      loop do
        previously_reachable = reachable.dup
        previously_reachable.each { |r|
          v = @rules[r]
          v = [v] unless v.kind_of?(Array)
          v.each { |p|
            p.each { |c|
              reachable.add(c) if @non_terminals.alphabet.include?(c.symbol) && @non_terminals.alphabet[c.symbol] == c.arity
            }
          }
        }
        break if previously_reachable == reachable
      end
      reachable
    end

    def reduce!
      pnt = productive_non_terminals
      r_prime = restrict_rules( pnt )
      @non_terminals = LibTree::define_system( alphabet: pnt.collect { |e| [e.symbol, e.arity] }.to_h )
      @rules = r_prime
      rnt = reachable_non_terminals
      r_second = restrict_rules( rnt )
      @non_terminals = LibTree::define_system( alphabet: rnt.collect { |e| [e.symbol, e.arity] }.to_h  )
      @rules = r_second
      self
    end

    def restrict_rules( nt )
      r = RuleSet::new
      @rules.each { |k, v|
        next unless nt.include?( k )
        v = [v] unless v.kind_of?(Array)
        v.each { |p|
          keep = true
          p.each { |c|
            keep = false unless nt.include?( c ) || (@terminals.alphabet.include?(c.symbol) && @terminals.alphabet[c.symbol] == c.arity)
          }
          r.append(k, p) if keep
        }
      }
      r
    end
    private :restrict_rules

    def reduce
      self.dup.reduce!
    end

    def rename_non_terminals(prefix = "nt")
      new_non_terminals = {}
      translate_table = {}
      @non_terminals.alphabet.each_with_index { |(s, a), i|
        nnt = "#{prefix}_#{i}"
        new_non_terminals[nnt] = a
        translate_table[[s,a]] = nnt
      }
      r = RuleSet::new
      @rules.each { |k,v|
        nk = k.dup
        nk.each { |n|
          n.set_symbol translate_table[ [n.symbol, n.arity] ] if translate_table.include?( [n.symbol, n.arity] )
        }
        v = [v] unless v.kind_of?(Array)
        v.each { |p|
          np = p.dup
          np.each { |n|
           n.set_symbol translate_table[ [n.symbol, n.arity] ] if translate_table.include?( [n.symbol, n.arity] )
          }
          r.append(nk, np)
        }
      }
      @non_terminals = LibTree::define_system( alphabet: new_non_terminals )
      @rules = r
      self
    end
  end

end
