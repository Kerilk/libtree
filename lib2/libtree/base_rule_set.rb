module LibTree

  class BaseRuleSet
    using RefineSet
    include Enumerable

    class Rule

      attr_reader :rhs
      attr_reader :capture

      def initialize(rhs, capture = nil)
        @rhs = rhs
        @capture = capture
      end

      def ==(other)
        other.kind_of?(self.class) && ( @rhs == other.rhs ) && ( @capture == other.capture )
      end

      alias eql? ==

      def to_a
        [ @rhs, @capture ]
      end

      def to_s
        "#{@rhs.to_s}#{@capture ? "#{@capture}" : ""}"
      end

      def dup
        self.class::new(@rhs.dup, @capture)
      end

    end #Rule

    def initialize
      @hash = {}
    end

    def dup
      new_rule_set = self.class::new
      new_rule_set.instance_variable_set(:@hash, @hash.dup)
      new_rule_set
    end

    def ==(other)
      other.kind_of?(self.class) && ( @hash == other.instance_variable_get(:@hash) )
    end

    alias eql? ==

    def hash
      @hash.hash
    end

    def self.compute_key(key)
      key
    end

    def to_s(separator = ", ")
      "<RuleSet: #{rules_to_s(separator)}>"
    end

    def rules_to_s(separator = ", ")
      "#{@hash.collect{ |k,v| "#{k} -> #{v.length > 1 ? "[#{v.join(", ")}]" : v.first.to_s}" }.join(separator)}"
    end

    def include?(key)
      @hash.include?(self.class::compute_key(key))
    end

    def [](key)
      @hash[self.class::compute_key(key)]
    end

    def []=(key,value)
      raise "invalid rule!" unless value.kind_of?(Array)
      @hash[self.class::compute_key(key)] = value
    end

    def delete(key, &block)
      @hash.delete(self.class::compute_key(key), &block)
    end

    def append(key, value, capture = nil)
      key = self.class::compute_key(key)
      if value.kind_of?(Rule)
        rule = value
      else
        rule = Rule::new(value, capture)
      end
      if @hash.include?(key)
        arr = @hash[key]
        arr.push rule
        arr.uniq!
        @hash[key] = arr
      else
        @hash[key] = [rule]
      end
    end

    def each(&block)
      if block
        @hash.each(&block)
      else
        to_enum(:each)
      end
    end

    def each_rule(&block)
      if block
        @hash.each { |k,v|
          v.each { |r|
            block.call(k, *r)
          }
        }
      else
        to_enum(:each_rule)
      end
    end

    def select(&block)
      h = @hash.select(&block)
      r = self.class::new
      r.instance_variable_set(:@hash, h)
      r
    end

    def reject!(&block)
      res = @hash.reject!(&block)
      return self if res
      nil
    end

    def reject(&block)
      h = @hash.reject(&block)
      r = self.class::new
      r.instance_variable_set(:@hash, h)
      r
    end

    def size
      @hash.size
    end

    def empty?
      @hash.size == 0
    end

  end

end
