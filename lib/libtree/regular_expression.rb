module LibTree

  class RegularExpression
    module Arithmetic
      def **(n, v = Variable::new(:sq))
        Iteration::new(self, n, v)
      end

      def /(a, b = nil)
        if b
          Concatenation::new(self, b, a)
        else
          Concatenation::new(self, a, Variable::new(:sq))
        end
      end
    end

    include Arithmetic

    attr_reader :re
    def initialize(re)
      @re = re
    end

    def to_grammar
      if @re.kind_of?(Term)
        counter = 0
        alphabet = {}
        nt_alphabet = {}
        rules = Grammar::RuleSet::new
        new_re = re.dup
        new_re.each(:pre) { |t|
          t.children.collect! { |c|
            if c.kind_of?(RegularExpression)
              g = c.to_grammar.rename_non_terminals("nt_#{counter}")
              counter += 1
              alphabet.merge!(g.terminals.alphabet)
              nt_alphabet.merge!(g.non_terminals.alphabet)
              g.rules.each { |k, v|
                rules.append(k, v)
              }
              g.axiom
            else
              c
            end
          }
          alphabet[t.symbol] = t.arity unless nt_alphabet[t.symbol]
        }
        terminals = LibTree::define_system( alphabet: alphabet )
        nt_alphabet[:base_nt0] = 0
        non_terminals = LibTree::define_system( alphabet: nt_alphabet )
        axiom = non_terminals.base_nt0
        rules.append(axiom, new_re)
        return RegularGrammar::new(axiom: axiom, non_terminals: non_terminals, terminals: terminals, rules: rules).normalize!.rename_non_terminals
      else
        return re.to_grammar
      end
    end

  end

  class Union < RegularExpression
  end

  class Iteration < RegularExpression

    attr_reader :number
    attr_reader :variable
    def initialize(re, number, variable = Variable::new(:sq) )
      super( re )
      @number = number
      @variable = variable
    end

    def to_grammar
      if @number == :*
        gre = @re.to_grammar
        terminals = gre.terminals
        non_terminals = gre.non_terminals
        rules = Grammar::RuleSet::new
        axiom = gre.axiom
        s = non_terminals.substitution(rules: { variable => axiom })
        gre.rules.each { |k, v|
          new_v = v.collect { |p|
            p * s
          }
          rules.append(k, new_v)
        }
        rules.append(axiom.dup, variable)
        return RegularGrammar::new(axiom: axiom, non_terminals: non_terminals, terminals: terminals, rules: rules).normalize!
      else
      end
    end

  end

  class Concatenation < RegularExpression

    attr_reader :re2
    attr_reader :variable
    def initialize(re, re2, variable = Variable::new(:sq) )
      super( re )
      @re2 = re2
      @re2 = RegularExpression::new(@re2) if @re2.kind_of?(Term)
      @variable = variable
    end

    def to_grammar
      gre = @re.to_grammar.rename_non_terminals("new_nt1_")
      gre2 = @re2.to_grammar.rename_non_terminals("new_nt2_")
      non_terminals = LibTree::define_system( alphabet: (gre.non_terminals.alphabet.to_a + gre2.non_terminals.alphabet.to_a).to_h )
      terminals = LibTree::define_system( alphabet: (gre.terminals.alphabet.to_a + gre2.terminals.alphabet.to_a).uniq.to_h )
      rules = Grammar::RuleSet::new
      axiom = gre.axiom
      axiom2 = gre2.axiom
      s = non_terminals.substitution(rules: { variable => axiom2 })
      gre.rules.each { |k, v|
        new_v = v.collect { |p|
          p * s
        }
        rules.append(k, new_v)
      }
      gre2.rules.each { |k, v|
        rules.append(k, v)
      }
      alphabet = (gre.terminals.alphabet.to_a + gre2.terminals.alphabet.to_a).uniq.to_h
      alphabet.delete( variable.symbol )
      terminals = LibTree::define_system( alphabet: alphabet )
      return RegularGrammar::new(axiom: axiom, non_terminals: non_terminals, terminals: terminals, rules: rules).normalize!.rename_non_terminals
     end

  end

  class Term

    def **(*args, &block)
      RegularExpression::new(self).**(*args, &block)
    end

    def /(*args, &block)
      RegularExpression::new(self)./(*args, &block)
    end

  end

end
