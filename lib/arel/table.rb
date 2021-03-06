module Arel
  class Table
    include Arel::Crud

    @engine = nil
    class << self; attr_accessor :engine; end

    attr_accessor :name, :engine, :aliases, :table_alias

    def initialize name, engine = Table.engine
      @name    = name.to_s
      @engine  = engine
      @columns = nil
      @aliases = []
      @table_alias = nil
      @primary_key = nil

      if Hash === engine
        @engine  = engine[:engine] || Table.engine

        # Sometime AR sends an :as parameter to table, to let the table know
        # that it is an Alias.  We may want to override new, and return a
        # TableAlias node?
        @table_alias = engine[:as] unless engine[:as].to_s == @name
      end
    end

    def primary_key
      @primary_key ||= begin
        primary_key_name = @engine.connection.primary_key(name)
        # some tables might be without primary key
        primary_key_name && self[primary_key_name]
      end
    end

    def alias name = "#{self.name}_2"
      Nodes::TableAlias.new(name, self).tap do |node|
        @aliases << node
      end
    end

    def from table
      SelectManager.new(@engine, table)
    end

    def joins manager
      if $VERBOSE
        warn "joins is deprecated and will be removed in 3.0.0"
        warn "please remove your call to joins from #{caller.first}"
      end
      nil
    end

    def join relation, klass = Nodes::InnerJoin
      return from(self) unless relation

      case relation
      when String, Nodes::SqlLiteral
        raise if relation.blank?
        from Nodes::StringJoin.new(self, relation)
      else
        from klass.new(self, relation, nil)
      end
    end

    def group *columns
      from(self).group(*columns)
    end

    def order *expr
      from(self).order(*expr)
    end

    def where condition
      from(self).where condition
    end

    def project *things
      from(self).project(*things)
    end

    def take amount
      from(self).take amount
    end

    def skip amount
      from(self).skip amount
    end

    def having expr
      from(self).having expr
    end

    def columns
      if $VERBOSE
        warn <<-eowarn
(#{caller.first}) Arel::Table#columns is deprecated and will be removed in
Arel 3.0.0 with no replacement.  PEW PEW PEW!!!
        eowarn
      end
      @columns ||=
        attributes_for @engine.connection.columns(@name, "#{@name} Columns")
    end

    def [] name
      ::Arel::Attribute.new self, name.to_sym
    end

    def select_manager
      SelectManager.new(@engine)
    end

    def insert_manager
      InsertManager.new(@engine)
    end

    private

    def attributes_for columns
      return nil unless columns

      columns.map do |column|
        Attributes.for(column).new self, column.name.to_sym
      end
    end

    @@table_cache = nil
    def self.table_cache engine # :nodoc:
      if $VERBOSE
        warn <<-eowarn
(#{caller.first}) Arel::Table.table_cache is deprecated and will be removed in
Arel 3.0.0 with no replacement.  PEW PEW PEW!!!
        eowarn
      end
      @@table_cache ||= Hash[engine.connection.tables.map { |x| [x,true] }]
    end
  end
end
