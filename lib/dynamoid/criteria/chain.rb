# encoding: utf-8
module Dynamoid #:nodoc:
  module Criteria

    # The class object that gets passed around indicating state of a building query.
    # Also provides query execution.
    class Chain
      attr_accessor :query, :source, :index, :values
      include Enumerable
      
      def initialize(source)
        @query = {}
        @source = source
      end
      
      def where(args)
        args.each {|k, v| query[k] = v}
        self
      end
      
      def all
        records
      end
      
      def first
        records.first
      end
      
      def each(&block)
        records.each(&block)
      end
      
      private
      
      def records
        return records_with_index unless index.empty?
        records_without_index
      end
      
      def records_with_index
        ids = Dynamoid::Adapter.read(source.index_table_name(index), source.key_for_index(index, values_for_index))
        if ids.nil? || ids.empty?
          []
        else
          Array(source.find(ids[:ids].to_a))
        end
      end
      
      def records_without_index
        if Dynamoid::Config.warn_on_scan
          Dynamoid.logger.warn 'Queries without an index are forced to use scan and are generally much slower than indexed queries!'
          Dynamoid.logger.warn "You can index this query by adding this to #{source.to_s.downcase}.rb: index [#{source.attributes.sort.collect{|attr| ":#{attr}"}.join(', ')}]"
        end
        Dynamoid::Adapter.scan(source.table_name, query).collect {|hash| source.new(hash)}
      end
      
      def values_for_index
        [].tap {|arr| index.each{|i| arr << query[i]}}
      end
      
      def index
        key = query.keys.sort.collect(&:to_sym)
        index = source.indexes.select {|k, v| v[:hash_key] == query.keys.sort.collect(&:to_sym)}
        return [] if index.blank?
        index[key][:hash_key]
      end
    end
    
  end
  
end