module LibTree

  class Automaton
    using RefineSet

    class Equivalence < Set

      def equivalent?(s1, s2)
        self.each { |subset|
          return false if subset.include?(s1) && !subset.include?(s2)
        }
        true
      end

      def equivalence(s)
        self.each { |subset|
          return subset if subset.include?(s)
        }
        nil
      end

    end

    class RuleSet < Hash

      class Rule < Term

        def ==(other)
          self.class === other && @symbol == other.symbol && @children == other.children
        end

        alias eql? ==

        def hash
          @symbol.hash ^ @children.hash
        end

      end #Rule

      def self.compute_rule(key)
        return key if key.kind_of?(Symbol)
        r = Rule::new(key.symbol)
        r.children.push *key.children.collect { |c| c.kind_of?(Term) ? c.symbol : c }
        r
      end

      def [](key)
        super(RuleSet::compute_rule(key))
      end

      def []=(key,value)
        super(RuleSet::compute_rule(key), value)
      end

      def delete(key)
        super(RuleSet::compute_rule(key))
      end

    end #RuleSet

    attr_reader :system
    attr_reader :rules
    attr_reader :states
    attr_reader :final_states
    attr_reader :order
    def initialize( system:, states:, final_states:, rules:, order: :post)
      @system = system
      @states = Set[*states]
      @final_states = Set[*final_states]
      @rules =  RuleSet::new
      rules.each { |k, v|
        @rules[k] = v
      }
      @order = order
    end

    def to_s
      <<EOF
<Automaton:
  system: #{@system}
  states: #{@states.to_s}
  final_states: #{@final_states.to_s}
  order: #{@order}
  rules:
    #{@rules.collect{ |k,v| "#{k} -> #{v.kind_of?(Array) ? "[#{v.join(", ")}]" : v.to_s}" }.join("\n    ")}
>
EOF
    end

    def rename_states
      state_mapping = @states.each_with_index.collect{ |s,i| [s, :"qr#{i}"] }.to_h
      new_states = Set::new(@states.collect{ |s| state_mapping[s]})
      new_final_states = Set::new(@final_states.collect{ |s| state_mapping[s]})
      s = @system.substitution(rules: state_mapping)
      new_rules = RuleSet::new
      @rules.each { |k, v|
        new_rules[s[k]] = state_mapping[v] ? state_mapping[v] : v
      }
      @states = new_states
      @final_states = new_final_states
      @rules = new_rules
      return self
    end

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
      Automaton::new( system: @system, states: @states.to_a, final_states: @final_states.to_a, rules: @rules, order: @order )
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
              equivalent = true
              @system.alphabet.select{ |sym, arity| arity > 0}.each { |sym, arity|
                @states.to_a.repeated_permutation(arity - 1).each { |perm|
                  (0..(arity-1)).each { |pos|
                    new_perm1 = perm.dup.insert(pos, s)
                    new_perm2 = perm.dup.insert(pos, s2)
                    q1 = @rules[@system.send(sym, *new_perm1)]
                    q2 = @rules[@system.send(sym, *new_perm2)]
                    if !previous_equivalence.equivalent?(q1, q2)
                      equivalent = false
                      break
                    end
                  }
                  break unless equivalent
                }
                break unless equivalent
              }
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

  end #Automaton

  class Run
    attr_reader :tree

    def initialize(automaton, tree)
      @automaton = automaton.remove_epsilon_rules
      @tree = tree.dup
      @state = @tree.each(automaton.order)
    end

    def move
      node = @state.next
      s = @automaton.rules[node]
      if s
        if s.kind_of?(Array)
          node.set_symbol s.sample
        else
          node.set_symbol s
        end
      end
      return self
    end

    def successful?
      @automaton.final_states.include?(@tree.root)
    end

    def run
      begin
        loop do
          move
        end
      rescue StopIteration
      end
      successful?
    end

  end

end
