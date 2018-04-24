require 'graphviz'

module LibTree
  class Term

    def to_graphviz( g = GraphViz::new( :G, :type => "strict digraph" ) )
      to_graphviz_node(g)
      g
    end

    def to_graphviz_node( g )
      n =  g.add_nodes( self.object_id.to_s )
      n[:label] = "#{@symbol}#{@state ? "(#{@state.to_s})" : ""}"
      cs = children.collect { |c| c.kind_of?(Term) ? c.to_graphviz_node(g) : g.add_nodes( c.to_s ) }
      cs.each { |cn|
        g.add_edges(n, cn)
      }
      n
    end

  end
end
