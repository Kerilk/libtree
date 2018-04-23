module LibTree

  class BaseRuleSet
    using RefineSet
    include Enumerable

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

    def self.compute_rule(key)
      key
    end

    def to_s(separator = ", ")
      "<RuleSet: #{rules_to_s(separator)}>"
    end

    def rules_to_s(separator = ", ")
      "#{@hash.collect{ |k,v| "#{k} -> #{v.length > 1 ? "[#{v.join(", ")}]" : v.first.to_s}" }.join(separator)}"
    end

    def include?(key)
      @hash.include?(self.class::compute_rule(key))
    end

    def [](key)
      @hash[self.class::compute_rule(key)]
    end

    def []=(key,value)
      raise "invalid rule!" unless value.kind_of?(Array)
      @hash[self.class::compute_rule(key)] = value
    end

    def delete(key, &block)
      @hash.delete(self.class::compute_rule(key), &block)
    end

    def append(key, value)
      value = [value] unless value.kind_of?(Array)
      key = self.class::compute_rule(key)
      if @hash.include?(key)
        old_value = @hash[key]
        @hash[key] = (old_value + value).uniq
      else
        @hash[key] = value
      end
    end

    def each(&block)
      @hash.each(&block)
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

  end

end
