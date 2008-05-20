module Arel
  class Order < Compound
    attr_reader :orderings
    
    def initialize(relation, *orderings)
      @relation, @orderings = relation, orderings.collect { |o| o.bind(relation) }
    end

    def orders
      orderings + relation.orders
    end
    
    def ==(other)
      Order       === other          and
      relation    ==  other.relation and
      orderings   ==  other.orderings
    end
  end
end