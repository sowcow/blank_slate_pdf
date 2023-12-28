require 'delegate'

module BS
  class Base
    class << self
      extend Forwardable
      delegate %i[
        []
        generate
        integrate
      ] => :new
    end

    def self.api name
      singleton_class.delegate name => :new
    end

    def self.[] key
      new key: key
    end

    def initialize key: self.class.const_get(:KEY)
      @key = key
    end

    def key name=nil
      if name.nil?
        @key
      else
        :"#{@key}_#{name}"
      end
    end
  end
end
