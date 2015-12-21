require 'ast'
module ATP
  module AST
    class Node < ::AST::Node
      include Factories

      def initialize(type, children = [], properties = {})
        # Always use strings instead of symbols in the AST, makes serializing
        # back and forward to a string easier
        children = children.map { |c| c.is_a?(Symbol) ? c.to_s : c }
        super type, children, properties
      end

      # Create a new node from the given S-expression (a string)
      def self.from_sexp(sexp)
        @parser ||= Parser.new
        @parser.string_to_ast(sexp)
      end

      # Adds an empty node of the given type to the children unless another
      # node of the same type is already present
      def ensure_node_present(type)
        if children.any? { |n| n.type == type }
          self
        else
          updated(nil, children + [n0(type)])
        end
      end

      # Returns the value at the root of an AST node like this:
      #
      #   node # => (module-def
      #               (module-name
      #                 (SCALAR-ID "Instrument"))
      #
      #   node.value  # => "Instrument"
      #
      # No error checking is done and the caller is responsible for calling
      # this only on compatible nodes
      def value
        val = children.first
        val = val.children.first while val.respond_to?(:children)
        val
      end

      # Add the given nodes to the children
      def add(*nodes)
        updated(nil, children + nodes)
      end

      # Returns the first child node of the given type that is found
      def find(type)
        nodes = find_all(type)
        nodes.first
      end

      # Returns an array containing all child nodes of the given type(s)
      def find_all(*types)
        Extractor.new.process(self, types)
      end

      def to_h
        h = {}
        children.each do |node|
          h[node.type] = node.children.map { |n| n.is_a?(AST::Node) ? n.to_h : n }
        end
        h
      end
    end
  end
end
