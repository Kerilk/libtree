module LibTree

  class Automaton < BaseAutomaton
    using RefineSet

    attr_reader :final_states

    @order = :post

    def initialize( system:, states:, final_states:, rules:)
      @system = system
      @states = Set[*states]
      @final_states = Set[*final_states]
      @rules =  RuleSet::new
      rules.each { |k, v|
        @rules[k] = v
      }
    end

    def to_s
      <<EOF
<Automaton:
  system: #{@system}
  states: #{@states.to_s}
  final_states: #{@final_states.to_s}
  order: #{order}
  rules:
    #{@rules.collect{ |k,v| "#{k} -> #{v.kind_of?(Array) ? "[#{v.join(", ")}]" : v.to_s}" }.join("\n    ")}
>
EOF
    end

    def run(tree, rewrite: true)
      Run::new(self, tree, rewrite: rewrite)
    end

    def size
      @states.size + @rules.rules_size
    end

    def rename_states(prefix = "qr")
      state_mapping = @states.each_with_index.collect{ |s,i| [s, :"#{prefix}#{i}"] }.to_h
      new_states = Set::new(@states.collect{ |s| state_mapping[s]})
      new_final_states = Set::new(@final_states.collect{ |s| state_mapping[s]})
      s = @system.substitution(rules: state_mapping)
      new_rules = RuleSet::new
      @rules.each { |k, v|
        new_rules[s[k]] = s[v]
      }
      @states = new_states
      @final_states = new_final_states
      @rules = new_rules
      return self
    end

    def union(other)
      raise "Systems are different! #{@system} != #{other.system}!" if @system != other.system
      automaton1 = self.determinize.complete.rename_states("qr1_")
      automaton2 = other.determinize.complete.rename_states("qr2_")
      s1 = automaton1.states.to_a
      s2 = automaton2.states.to_a
      fs1 = automaton1.final_states.to_a
      fs2 = automaton2.final_states.to_a
      new_states = s1.product( s2 ).to_set
      new_final_states = fs1.product( s2 ).to_set | s1.product( fs2 ).to_set
      new_rules = RuleSet::new
      @system.alphabet.each { |sym, arity|
        new_states.to_a.repeated_permutation(arity).each { |perm|
          os1 = automaton1.rules[@system.send(sym, *perm.collect{|e| e.first})]
          os2 = automaton2.rules[@system.send(sym, *perm.collect{|e| e.last })]
          new_rules[@system.send(sym, *perm.collect(&:to_set))] = Set[os1, os2]
        }
      }
      new_states = new_states.collect(&:to_set).to_set
      new_final_states = new_final_states.collect(&:to_set).to_set
      Automaton::new(system: @system, states: new_states, final_states: new_final_states, rules: new_rules)
    end
    alias | union

    def complement
      return determinize.complement unless deterministic?
      return complete.complement unless complete?
      Automaton::new(system: @system, states: @states, final_states: @states - @final_states, rules: @rules)
    end
    alias ~ complement

    def intersection(other)
      ~(complement | ~other)
    end
    alias & intersection

    def remove_epsilon_rules!
      e_r = epsilon_rules
      return self if epsilon_rules.empty?

      non_epsilon_rules = @rules.reject { |k, v| k.kind_of? Symbol }
      epsilon_closures = @states.collect { |s| [s, Set[s]] }
      loop do
        previous_epsilon_closures = epsilon_closures.collect { |s, c| [s, c.dup] }
        epsilon_closures.each { |s, c|
	  c.to_a.each { |st|
            new_state = e_r[st]
            c.add(new_state) if new_state
          }
        }
        break if previous_epsilon_closures == epsilon_closures
      end
      epsilon_closures = epsilon_closures.to_h
      new_rules = RuleSet::new
      non_epsilon_rules.each { |k, v|
        states = epsilon_closures[v].to_a
        states = states.first if states.size == 1
        new_rules[k] = states
      }
      @rules = new_rules
      return self
    end

    def remove_epsilon_rules
      dup.remove_epsilon_rules!
    end

    def epsilon_rules
      @rules.select { |k, v|
        k.kind_of? Symbol
      }
    end

    def epsilon_rules?
      ! epsilon_rules.empty?
    end

    def ==(other)
      self.class === other && @system == other.system && @rules == other.rules && @states == other.states && @final_states == other.final_states
    end

    alias eql? ==

    def dup
      self.class::new( system: @system, states: @states.to_a, final_states: @final_states.to_a, rules: @rules )
    end

    def deterministic?
      return false if epsilon_rules?
      rules.each { |k,v|
        return false if v.kind_of?(Array)
      }
      true
    end

    def complete?
      @system.alphabet.each { |sym, arity|
        if arity > 0
          @states.to_a.repeated_permutation(arity) { |perm|
            return false unless rules[@system.send(sym, *perm)]
          }
        else
          return false unless rules[@system.send(sym)]
        end
      }
      return true
    end

    def complete!
      return self if complete?
      @states.add(:__dead)
      @system.alphabet.each { |sym, arity|
        if arity > 0
          @states.to_a.repeated_permutation(arity) { |perm|
            @rules[@system.send(sym, *perm)] = :__dead unless @rules[@system.send(sym, *perm)]
          }
        else
          @rules[@system.send(sym)] = :__dead unless @rules[@system.send(sym)]
        end
      }
      return self
    end

    def complete
      dup.complete!
    end

    def reduce!
      remove_epsilon_rules!
      marked_states = Set[]
      available_rules = @rules.dup
      marked_rules = RuleSet::new
      loop do
        previously_marked_states = marked_states.dup
        previously_marked_rules = marked_rules.dup
        @system.alphabet.each { |sym, arity|
          marked_states.to_a.repeated_permutation(arity) { |perm|
            k = @system.send(sym, *perm)
            v = available_rules.delete(k)
            if v
              if v.kind_of? Array
                marked_states.merge(v)
              else
                marked_states.add(v)
              end
              marked_rules[k] = v
            end
          }
        }
        break if previously_marked_states == marked_states && previously_marked_rules == marked_rules
      end
      @rules = marked_rules
      @states = marked_states
      @final_states &= @states
      self
    end

    def reduce
      dup.reduce!
    end

    def reduced?
      self == reduce
    end

    def determinize!
      remove_epsilon_rules!
      return self if deterministic?
      new_states = Set[]
      new_rules = RuleSet::new
      loop do
        previously_new_states = new_states.dup
        previously_new_rules = new_rules.dup
        @system.alphabet.each { |sym, arity|
          new_states.to_a.repeated_permutation(arity) { |perm|
            perm = perm.collect(&:to_a)
            if perm != []
              products = perm.first.product(*perm[1..-1])
            else
              products = [[]]
            end
            new_state = Set[]
            products.each { |p|
              k = @system.send(sym, *p)
              v = @rules[k]
              if v
                if v.kind_of? Array
                  new_state.merge v
                else
                  new_state.add v
                end
              end
            }
            unless new_state == Set[]
              new_states.add new_state
              perm = perm.collect(&:to_set)
              new_rules[@system.send(sym, *perm)] = new_state
            end
          }
        }
        break if previously_new_rules == new_rules && previously_new_states == new_states
      end
      @rules = new_rules
      @states = new_states
      new_final_states = Set[]
      new_final_states.merge @states.select{ |s| @final_states.collect{|fs| s.include? fs }.include? true }
      @final_states = new_final_states
      self
    end

    def determinize
      dup.determinize!
    end

    def minimize!
      reduce!
      determinize!
      complete!
      equivalence = Equivalence[ @final_states.dup, @states - @final_states ]
      loop do
        previous_equivalence = equivalence
        equivalence = Equivalence[]
        previous_equivalence.each { |e|
          e_prime = e.dup
          while e_prime.size > 0 do
            s = e_prime.first
            eq_state = Set[s]
            sub_e = e_prime - eq_state
            sub_e.each { |s2|
              equivalent = catch( :found ) do
                @system.alphabet.select{ |sym, arity| arity > 0}.each { |sym, arity|
                  @states.to_a.repeated_permutation(arity - 1).each { |perm|
                    (0..(arity-1)).each { |pos|
                      new_perm1 = perm.dup.insert(pos, s)
                      new_perm2 = perm.dup.insert(pos, s2)
                      q1 = @rules[@system.send(sym, *new_perm1)]
                      q2 = @rules[@system.send(sym, *new_perm2)]
                      if !previous_equivalence.equivalent?(q1, q2)
                        throw :found, false
                      end
                    }
                  }
                }
                true
              end
              eq_state.add(s2) if equivalent
            }
            e_prime -= eq_state
            equivalence.add eq_state
          end
        }
        break if previous_equivalence == equivalence
      end
      new_states = Set[ *equivalence.to_a ]
      new_final_states = Set[]
      new_states.each { |set|
        final = false
        set.each { |s|
          if @final_states.include?(s)
            final = true
            break
          end
        }
        new_final_states.add(set) if final
      }
      new_rules = RuleSet::new
      @system.alphabet.each { |sym, arity|
         new_states.to_a.repeated_permutation(arity).each { |perm|
           old_state = @rules[@system.send(sym, *perm.collect{|e| e.first})]
           new_rules[@system.send(sym, *perm)] = equivalence.equivalence( old_state )
         }
      }
      @states = new_states
      @final_states = new_final_states
      @rules = new_rules
      self
    end

    def minimize
      dup.minimize!
    end

  end

end