#' @title Find the largest common connected subgraph(LCCS)
#'
#' @description Assume two aligned graphs, find the largest common connect subgraph of these
#' two graphs, which is an induced connected subgraph of both graphs that has as many vertices
#' as possible.
#'
#' @param A A matrix or an igraph object. Adjacency matrix of \eqn{G_1}.
#' @param B A matrix or an igraph object. Adjacency matrix of \eqn{G_2}.
#' @param min_degree A number. Defines the level of connectness of the obtained largest common
#' connected subgraph. The induced subgraph is an graph with a minimum degree of vertices equal
#' to min_degree.
#'
#' @rdname largest_common_cc
#'
#' @return \code{largest_common_cc} returns the common largest connected subgraphs of
#' two aligned graphs in the igraph object form and a logical vector indicating which vertices in
#' the original graphs remain in the induced subgraph.
#'
#' @examples
#' cgnp_pair <- sample_correlated_gnp_pair(n = 10, corr =  0.7, p =  0.2)
#' g1 <- cgnp_pair$graph1
#' g2 <- cgnp_pair$graph2
#' # put no constraint on the minimum degree of the common largest conncect subgraph
#' lccs1 <- largest_common_cc(g1, g2, min_degree = 1)
#' # induced subgraph
#' lccs1$g1
#' lccs1$g2
#' # label of vertices of the induced subgraph in the original graph
#' V(A)[lccs1$keep]
#' 
#' # obtain a common largest connect subgraph with each vertex having a minimum degree of 3
#' lccs3 <- largest_common_cc(g1, g2, min_degree = 3)
#' @export
#'
largest_common_cc <- function(A, B, min_degree = 1){
  keep <- rep(TRUE, igraph::vcount(A))
  while (!(igraph::is_connected(A) && igraph::is_connected(B))){
    cc1 <- igraph::components(A)
    cc2 <- igraph::components(B)

    lcc1 <- which.max(cc1$csize)
    lcc2 <- which.max(cc2$csize)

    vlcc1 <- cc1$membership == lcc1
    vlcc2 <- cc2$membership == lcc2

    vlcc <- vlcc1 & vlcc2
    keep[keep] <- vlcc

    A <- igraph::induced_subgraph(A, igraph::V(A)[vlcc])
    B <- igraph::induced_subgraph(B, igraph::V(B)[vlcc])

    if(min_degree > 1){
      good_deg <- (igraph::degree(A) >= min_degree) &
        (igraph::degree(B) >= min_degree)
      keep[keep] <- good_deg

      A <- igraph::induced_subgraph(A, good_deg)
      B <- igraph::induced_subgraph(B, good_deg)
    }
  }

  list(g1 = A, g2 = B, keep = keep)
}
