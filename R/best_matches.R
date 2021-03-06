#' @title Choose best matches
#'
#' @description Find a set of vertices pairs in the order of goodness of matching according to a
#' specified measure.
#'
#' @param A A matrix or an igraph object. Adjacency matrix of \eqn{G_1}.
#' @param B A matrix or an igraph object. Adjacency matrix of \eqn{G_2}.
#' @param measure A character. Measure for computing goodness of matching.
#' @param num An integer. Number of pairs of best matched vertices needed.
#' @param x A vector of logical. \code{TRUE} indicates the corresponding vertex in \eqn{G_1} is of 
#'   interest in finding best matched vertices. Length of vector should be the number of vertices 
#'   of graphs.
#' @param match_corr A matrix or data frame. Graph matching correspondence between \eqn{G_1} and 
#'   \eqn{G_2} with the first column represents indices in \eqn{G_1} and the second column represents
#'   indices in \eqn{G_2}.
#'
#' @return \code{best_matches} returns a data frame with the indices of best matched vertices
#' in \eqn{G_1} named \code{A_best} and the indices of best matched vertices in \eqn{G_2} named
#' \code{B_best}.
#'
#' @examples
#' cgnp_pair <- sample_correlated_gnp_pair(n = 50, corr =  0.3, p =  0.5)
#' g1 <- cgnp_pair$graph1
#' g2 <- cgnp_pair$graph2
#' seeds <- 1:50 <= 10
#' nonseeds <- !seeds
#' match <- graph_match_FW(g1, g2, seeds)
#'
#' # Application: select best matched seeds from non seeds as new seeds, and do the
#' # graph matching iteratively to get higher matching accuracy
#' best_matches(g1, g2, "row_perm_stat", num = 5, x = nonseeds, match$corr)
#'
#'
#' @export
#'
best_matches <- function(A, B, measure, num, x, match_corr){
  A <- A[match_corr[,1], match_corr[,1]]
  B <- B[match_corr[,2], match_corr[,2]]
  nv <- nrow(A)
  x <- x[match_corr[,1]]

  # calculate measure stat
  stat <- do.call(measure,list(A,B))
  stat_in <- stat[x]

  # find top ranking nodes pairs
  rstat <- sort(stat_in)
  topstat <- rstat[1:num]
  topindex <- unique(unlist(sapply(topstat, function(top) which(stat==top))))
  topindex <- sapply(topindex, function(top){ifelse(top %in% c(1:nv)[!x],0,top)})
  topindex <- topindex[topindex!=0]
  topindex <- topindex[1:num]

  top_matches <- match_corr[topindex, ]

  best_matches <- data.frame(A_best=top_matches$corr_A, B_best=top_matches$corr_B)
  best_matches
}
