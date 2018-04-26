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
        @rules.each_rule { |k, p|
          prod = true
          p.each { |c|
            prod = false unless previously_productive.include?( c ) || (@terminals.alphabet.include?(c.symbol) && @terminals.alphabet[c.symbol] == c.arity)
          }
          productive.add(k) if prod
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
          v.each { |p|
            p.rhs.each { |c|
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
      @rules.each_rule { |k, p|
        next unless nt.include?( k )
        keep = true
        p.each { |c|
          keep = false unless nt.include?( c ) || (@terminals.alphabet.include?(c.symbol) && @terminals.alphabet[c.symbol] == c.arity)
        }
        r.append(k, p) if keep
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
        nnt = "#{prefix}_#{i}".to_sym
        new_non_terminals[nnt] = a
        translate_table[[s,a]] = nnt
      }
      r = RuleSet::new
      @rules.each_rule { |k, p|
        nk = k.dup
        nk.each { |n|
          n.set_symbol translate_table[ [n.symbol, n.arity] ] if translate_table.include?( [n.symbol, n.arity] )
        }
        np = p.dup
        np.each { |n|
         n.set_symbol translate_table[ [n.symbol, n.arity] ] if translate_table.include?( [n.symbol, n.arity] )
        }
        r.append(nk, np)
      }
      @non_terminals = LibTree::define_system( alphabet: new_non_terminals )
      @rules = r
      @axiom = Term::new(translate_table[ [@axiom.symbol, @axiom.arity] ])
      self
    end

    def normalize!
      reduce!
      nts = @non_terminals.alphabet.collect { |k,v|
        Term::new(k)
      }.to_set
      counter = 0
      loop do
        previous_non_terminals = nts.dup
        previous_rules = @rules
        @rules = RuleSet::new
        previous_rules.each_rule { |k, p|
          p previous_rules if p.kind_of?(Array)
          if p.arity > 0
            p.children.collect! { |c|
              unless nts.include?(c) || c.kind_of?(Square)
                new_name = "new_nt_#{counter}".to_sym
                new_term = Term::new(new_name)
                nts.add(new_term)
                @rules.append(new_term, c)
                counter += 1
                new_term.dup
              else
                c
              end
            }
          end
          @rules.append(k, p)
        }
        break if nts == previous_non_terminals
      end
      @non_terminals = LibTree::define_system( alphabet: nts.collect { |e| [e.symbol, e.arity] }.to_h  )
      loop do
        previous_rules = @rules
        @rules = RuleSet::new
        previous_rules.each_rule { |k, p|
          if nts.include?(p)
            v2 = previous_rules[p]
            v2.each { |p2|
              new_p2 = p2.dup
              @rules.append(k, p2)
            }
          else
            @rules.append(k, p)
          end
        }
        break if previous_rules == @rules
      end
      reduce!
    end

    def normalize
      self.dup.normalize!
    end

    def top_down_automaton
      dup.top_down_automaton!
    end

    def top_down_automaton!
      normalize!
      nts_states_map = @non_terminals.alphabet.collect { |k, a| [ Term::new(k), "#{k}".to_sym ] }.to_h
      states = nts_states_map.values
      r = RuleSet::new
      @rules.each_rule { |k, p|
        s = nts_states_map[k]
        new_k = Term::new( p.symbol, * p.arity.times.collect { |i| "x#{i}".to_sym }, state: s )
        new_p = Term::new( p.symbol, * p.children.collect { |c| nts_states_map[c] } )
        r.append(new_k, new_p)
      }
      LibTree::TopDownAutomaton::new(system: @terminals, states: states, initial_states: [ nts_states_map[@axiom] ], rules: r)
    end

    def bottom_up_automaton
      dup.bottom_up_automaton!
    end

    def bottom_up_automaton!
      normalize!
      nts_states_map = @non_terminals.alphabet.collect { |k, a| [ Term::new(k), "#{k}".to_sym ] }.to_h
      states = nts_states_map.values
      r = RuleSet::new
      @rules.each_rule { |k, p|
        s = nts_states_map[k]
        new_p = Term::new( p.symbol, * p.children.collect { |c| nts_states_map[c] } )
        r.append( new_p, s )
      }
      LibTree::Automaton::new(system: @terminals, states: states, final_states: [ nts_states_map[@axiom] ], rules: r)
    end

  end

end
