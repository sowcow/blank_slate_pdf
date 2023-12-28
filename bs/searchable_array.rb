# probably I need to remove .nil? valued pairs from pattern

class Array
  def to_sa
    SearchableArray.call self
    self
  end
end

module SearchableArray
  extend self

  # assumes .data on members for search
  #
  def call array

    # could take many matchers -> merge results?
    def array.get matcher #, cache: nil - not syntactically friendly
      matcher = SearchableArray.expand_matcher matcher
      find &matcher
    end

    def array.xs matcher
      matcher = SearchableArray.expand_matcher matcher
      select &matcher
    end
  end

  def expand_matcher matcher
    case matcher
    when Symbol
      symbol = matcher
      matcher = { type: symbol }
    end

    case matcher
    when Hash
      hash = matcher
      matcher = proc { |x|
        hash.all? { |k, v|
          v === x.data[k]
        }
      }
    when Proc
      # fine
    else
      raise "unexpected matcher: #{matcher}"
    end

    matcher
  end
end
