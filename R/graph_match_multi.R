#' @title Multiple Graph Match Methods
#'
#' @description Match two lists of graphs, returns a list of graph matching results,
#' including matching correspondence vector of \eqn{G_2} with respect to \eqn{G_1},
#' doubly stochastic matrix and permutation matrix.
#'
#' @param A A list of graphs (or igraph objects)
#' @param B A list of graphs (or igraph objects)
#' @param seeds A vector of integers or logicals, a matrix or a data frame. If there is no error in seeds input can be
#' a vector of seed indices in \eqn{G_1}. Or if there exists error in seeds, input in the form of a
#' matrix or a data frame, with the first column being the indices of \eqn{G_1} and the second
#' column being the corresponding indices of \eqn{G_2}.
#' @param start A matrix or a character. Any \code{nns-by-nns} matrix or
#' character value like "bari" or "convex" to initialize the starting matrix.
#' @param max_iter An integer. Maximum iteration time.
#' @param tol A number. Tolerance of edge disagreements.
#' @param r A number. Threshold of neighboring pair scores.
#'
#' @return \code{graph_match_FW_multi} returns a list of graph matching results,
#' including match correspondence vector of \eqn{G_2} with respect to \eqn{G_1}
#' named \code{corr}, doubly stochastic matrix named \code{D}, permutation
#' matrix named \code{P} based on Frank-Wolfe methodology and iteration time of
#' the algorithm named \code{iter}.
#'
#' @examples
#'  gp_list <- replicate(3, sample_correlated_gnp_pair(100, .3, .5), simplify = FALSE)
#'  A <- lapply(gp_list, function(gp)gp[[1]])
#'  B <- lapply(gp_list, function(gp)gp[[2]])
#'  match <- graph_match_FW_multi(A, B, seeds = 1:10, start = "bari", max_iter = 20)
#'  match$corr
#'
#' @export
#'
graph_match_FW_multi <- function(A, B, seeds = NULL,
  start = "bari", max_iter = 20, similarity = NULL, lap_method = NULL){
  warning("graph_match_FW_multi is deprecated. Please use graph_match_FW.")
  # if(start == "convex"){
  #   stop("Convex start is not yet implemented for multiplex matching")
  # }

  # NEED TO 
  # this will make the graphs be matrices if they are igraph objects
  if(is.list(A) && !is.igraph(A)){
    A <- lapply(A, function(Al) Al[])
  } else {
    A <- list(A[])
  }
  if( is.list(B) && !is.igraph(B)){
    B <- lapply(B, function(Bl) Bl[])
  } else {
    B <- list(B[])
  }

  # Assume each list has all the same number of nodes within
  totv1 <- ncol(A[[1]])
  totv2 <- ncol(B[[1]])

  if(totv1 > totv2){
    diff <- totv1 - totv2
    B <- lapply(B, function(Bl)
      pad(Bl[], diff))
  }else if(totv1 < totv2){
    diff <- totv2 - totv1
    A <- lapply(A, function(Al)
      pad(Al[], diff))
  }
  nv <- nrow(A[[1]])


  seed_check <- check_seeds(seeds, nv)
  seeds <- seed_check$seeds
  nonseeds <- seed_check$nonseeds

  ns <- nrow(seeds)
  nn <- nv - ns

  P <- init_start(start = start, nns = nn,
    A = A[[1]], B = B[[1]], seeds = seeds)

  iter <- 0
  toggle <- TRUE

  # make a random permutation
  rp <- sample(nn)
  rpmat <- Matrix::Diagonal(nn)[rp, ]

  # seed to non-seed info
  s_to_ns <- get_s_to_ns(A, B, seeds, nonseeds, rp)

  P <- P[, rp]

  zero_mat <- Matrix::Matrix(0, nn, nn)
  if (is.null(similarity)){
    similarity <- zero_mat
  } else {
    similarity <- similarity %*% Matrix::t(rpmat)
  }

  # keep only nonseeds
  A <- lapply(A, function(Al) Al[nonseeds$A, nonseeds$A])
  B <- lapply(B, function(Bl) Bl[nonseeds$B, nonseeds$B][rp, rp])
  nc <- length(A)

  lap_method <- set_lap_method(lap_method, totv1, totv2)


  while(toggle && iter < max_iter){

    iter <- iter + 1
    # non-seed to non-seed info
    tAnn_P_Bnn <- zero_mat
    for( ch in 1:nc ){
      tAnn_P_Bnn <- tAnn_P_Bnn +
        Matrix::t(A[[ch]]) %*% P %*% B[[ch]]
    }

    Grad <- s_to_ns + tAnn_P_Bnn + similarity
    for(ch in 1:nc){
      Grad <- Grad + A[[ch]] %*% P %*% Matrix::t(B[[ch]])
    }

    ind <- do_lap(Grad, lap_method)

    ind2 <- cbind(1:nn, ind)
    Pdir <- Matrix::Diagonal(nn)
    Pdir <- Pdir[ind, ]
    ns_Pdir_ns <- zero_mat
    for(ch in 1:nc){
      ns_Pdir_ns <- ns_Pdir_ns +
        Matrix::t(A[[ch]])[, order(ind)] %*% B[[ch]]
    }

    c <- innerproduct(tAnn_P_Bnn, P)
    d <- innerproduct(ns_Pdir_ns, P) + sum(tAnn_P_Bnn[ind2])
    e <- sum(ns_Pdir_ns[ind2])
    u <- innerproduct(P, s_to_ns + similarity)
    v <- sum((s_to_ns + similarity)[ind2])
    if (c - d + e == 0 && d - 2 * e + u - v == 0) {
      alpha <- 0
    } else {
      alpha <- -(d - 2 * e + u - v)/(2 * (c - d + e))
    }
    f0 <- 0
    f1 <- c - e + u - v
    falpha <- (c - d + e) * alpha^2 + (d - 2 * e + u - v) *
      alpha

    if (alpha < 1 && alpha > 0 &&
        falpha > f0 && falpha > f1) {
      P <- alpha * P + (1 - alpha) * Pdir
    } else if (f0 > f1) {
      P <- Pdir
    } else {
      toggle <- F
    }
  }

  D_ns <- P

  corr_ns <- do_lap(P, lap_method)


  # undo rand perm here
  corr_ns <- rp[corr_ns]

  corr <- 1:nv
  corr[nonseeds$A] <- nonseeds$B[corr_ns]
  corr[seeds$A] <- seeds$B
  P <- Matrix::Diagonal(nv)[corr, ]
  D <- P
  D[nonseeds$A, nonseeds$B] <- D_ns %*% rpmat

  cl <- match.call()
  z <- list(
    call = cl, 
    corr = data.frame(corr_A = 1:totv1, corr_B = corr),
    ns = ns,
    P = P,
    D = D)
}


get_graph_triple <- function(g, weight, first_graph){
  if(first_graph){
    w <- sign(weight) * w
    list(w[1] * g[], w[2] * g[],
      splr_sparse_plus_constant(- w[3] * g[], w[3]))
  }
  else{
    list(g[], splr_sparse_plus_constant(- g[], 1), g[])
  }
}


graph_match_FW_multi_reward <- function(A, B, weight, ...){
  if( is.igraph(A) ){
    A <- list(A)
  }
  if( is.igraph(B) ){
    B <- list(B)
  }
  if(!is.list(A) && !is.list(B)){
    A <- list(A)
    B <- list(B)
  }
  A <- unlist(lapply(A, get_graph_triple,
    weight = weight, first_graph = TRUE), recursive = FALSE)
  B <- unlist(lapply(B, get_graph_triple,
    weight = weight, first_graph = FALSE), recursive = FALSE)

  graph_match_FW_multi(A, B, ...)
}

              
#' @export
graph_match_percolation_multi <- function (A, B, start = NULL, similarity = NULL, r = 2, alpha = 10) 
{
  A <- lapply(A, function(Al) Al[])
  B <- lapply(B, function(Bl) Bl[])
  
  n_A <- ncol(A[[1]])
  n_B <- ncol(B[[1]])
  P <- start * alpha
  Z <- c(0,0)
  nc <- length(A)
  M <- similarity
  for(ch in 1:nc){
    M <- M + t(A[[ch]]) %*% P %*% B[[ch]] + A[[ch]] %*% P %*% t(B[[ch]])
    gc()
  }
  
  while (ifelse(is.na(max(M)), 0, max(M)) >= r + max(similarity)) {
    max_ind <- which(M == max(M), arr.ind = TRUE)
    max_ind <- max_ind[sample(nrow(max_ind), 1), ]
    
    P[max_ind[1],] <- 0
    P[,max_ind[2]] <- 0
    P[max_ind[1], max_ind[2]] <- 1
    P[P>0] <- 1
    P <- diag(1 / rowSums(P)) %*% P
    
    M <- similarity
    for(ch in 1:nc){
      M <- M + t(A[[ch]]) %*% P %*% B[[ch]] + A[[ch]] %*% P %*% t(B[[ch]])
      gc()
    }
    #if(min(B)<0){
    #  delta_norm <- 2*delta_norm - matrix(1, nrow = n_A, ncol = n_B)
    #}
    Z <- rbind(Z, max_ind)
    M[Z[,1], ] <- -n_B
    M[,Z[,2]] <- -n_B
  }
  
  corr <- Z[-1,]
  if(is.null(nrow(corr))){
    corr <- Matrix(corr, ncol = 2)
  }
  colnames(corr) <- c("corr_A", "corr_B")
  corr
}




#' @export
graph_match_ExpandWhenStuck_multi <- function(A, B, start = NULL, similarity = NULL, r = 2, alpha = 5){
  # this will make the graphs be matrices if they are igraph objects
  A <- lapply(A, function(Al) Al[])
  B <- lapply(B, function(Bl) Bl[])
  
  n_A <- ncol(A[[1]])
  n_B <- ncol(B[[1]])
  P <- start * alpha
  Z <- c(0,0)
  nc <- length(A)
  M <- similarity
  for(ch in 1:nc){
    M <- M + t(A[[ch]]) %*% P %*% B[[ch]] + A[[ch]] %*% P %*% t(B[[ch]])
    gc()
  }
  
  seeds <- Matrix(0,2,2)
  # deferred percolation graph matching
  while(nrow(seeds) != 0){
    if(sum(seeds[1,])!=0){
      Pi <- Matrix(0, nrow = n_A, ncol = n_B)
      Pi[seeds] <- 1
      for(ch in 1:nc){
        M <- M + t(A[[ch]]) %*% Pi %*% B[[ch]] + A[[ch]] %*% Pi %*% t(B[[ch]])
        gc()
      }
    }
    
    # choose pairs with marks ge r
    while(max(M) >= r + max(similarity)){
      max_ind <- which(M == max(M), arr.ind = TRUE)
      max_ind <- max_ind[sample(nrow(max_ind), 1), ]
      
      # update mark matrix
      P[max_ind[1],] <- 0
      P[,max_ind[2]] <- 0
      P[max_ind[1], max_ind[2]] <- 1
      P[P>0] <- 1
      P <- diag(1 / rowSums(P)) %*% P
      if(sum(seeds[1,])!=0){
        P[seeds] <- 1 
      }
      
      M <- similarity
      for(ch in 1:nc){
        M <- M + t(A[[ch]]) %*% P %*% B[[ch]] + A[[ch]] %*% P %*% t(B[[ch]])
        gc()
      }
      #if(min(B)<0){
      #  delta_norm <- 2*delta_norm - matrix(1, nrow = n_A, ncol = n_B)
      #}
      Z <- rbind(Z, max_ind)
      M[Z[,1], ] <- -n_B
      M[,Z[,2]] <- -n_B
    }
    
    seeds_old <- seeds
    seeds <- which(M > 1e5+1, arr.ind = TRUE)
    
    if(nrow(seeds) == nrow(seeds_old)){
      if(sum(seeds == seeds_old)==2*nrow(seeds)){
        break
      }
    }
    if(nrow(Z)==n_A + 1){
      break
    }
  }
  
  # matching result
  corr <- Z[-1,]
  if(is.null(nrow(corr))){
    corr <- Matrix(corr, ncol = 2)
  }
  colnames(corr) <- c("corr_A","corr_B")
  corr
}


graph_match_mutual_multi <- function(A, B, start = NULL, similarity = NULL, alpha = 0.2, max_iter = 50){
  # this will make the graphs be matrices if they are igraph objects
  A <- lapply(A, function(Al) Al[])
  B <- lapply(B, function(Bl) Bl[])
  
  match <- Matrix(0,2,2)
  mutual3 <- match
  mutual21 <- match
  mutual22 <- match
  a0 <- 0 # number of seeds
  iter <- 0
  
  n_A <- ncol(A[[1]])
  n_B <- ncol(B[[1]])
  nc <- length(A)
  
  if(alpha==0){
    while(iter < max_iter & nrow(match) < n){
      P <- start
      P[match[,1],] <- 0
      P[,match[,2]] <- 0
      P[match] <- 1 # update permutation matrix by current matches
      P <- diag(1 / rowSums(P)) %*% P
      M <- similarity
      for(ch in 1:nc){
        M <- M + t(A[[ch]]) %*% P %*% B[[ch]] + A[[ch]] %*% P %*% t(B[[ch]])
        gc()
      }
      col_ind <- max.col(M[(a0+1):n_A,(a0+1):n_B], ties.method = "random") + a0 # strategy for solving ties: random
      row_ind <- max.col(t(M[(a0+1):n_A,(a0+1):n_B]), ties.method = "random") + a0 # strategy for solving ties: random
      col_max <- cbind(1:n_A, col_ind)
      row_max <- cbind(row_ind, 1:n_B)
      candidate <- rbind(col_max, row_max)
      dup <- duplicated(candidate)
      match <- candidate[dup,]
      iter <- iter + 1
      
    }
  } else{
    while(iter < max_iter & nrow(match) < n){
      P <- start
      P[match[,1],] <- 0
      P[,match[,2]] <- 0
      P[as.matrix(match)] <- 1 # update permutation matrix by current matches
      P <- diag(1 / rowSums(P)) %*% P
      P[as.matrix(mutual3)] <- alpha
      P[as.matrix(mutual21)] <- alpha * 3 / 2
      P[as.matrix(mutual22)] <- alpha * 3 / 2
      M <- similarity
      for(ch in 1:nc){
        M <- M + t(A[[ch]]) %*% P %*% B[[ch]] + A[[ch]] %*% P %*% t(B[[ch]])
        gc()
      }
      
      col_ind <- max.col(as.matrix(M[(a0+1):n_A,(a0+1):n_B]), ties.method = "random") + a0 # strategy for solving ties: random
      row_ind <- max.col(as.matrix(t(M[(a0+1):n_A,(a0+1):n_B])), ties.method = "random") + a0 # strategy for solving ties: random
      row_max1 <- cbind(1:n_A, col_ind) # pairs of nodes with highest score in each row
      col_max1 <- cbind(row_ind, 1:n_B) # pairs of nodes with highest score in each column
      
      MM <- M
      MM[row_max1] <- 0
      col_ind2 <- max.col(MM[(a0+1):n_A,(a0+1):n_B], ties.method = "random") + a0
      row_max2 <- cbind(1:n_A, col_ind2)
      
      MM <- M
      MM[col_max1] <- 0
      row_ind2 <- max.col(t(MM[(a0+1):n_A,(a0+1):n_B]), ties.method = "random") + a0
      col_max2 <- cbind(row_ind2, 1:n_B) 
      
      candidate1 <- rbind(col_max1, row_max1)
      dup1 <- duplicated(candidate1)
      match <- candidate1[dup1,]
      
      candidate21 <- rbind(col_max1, row_max2)
      dup21 <- duplicated(candidate21)
      mutual21 <- candidate21[dup21,]
      
      candidate22 <- rbind(col_max2, row_max1)
      dup22 <- duplicated(candidate22)
      mutual22 <- candidate22[dup22,]
      
      candidate3 <- rbind(col_max2, row_max2)
      dup3 <- duplicated(candidate3)
      mutual3 <- candidate3[dup3,]
      
      iter <- iter + 1
      
    }
  }
  
  corr <- match
  if(is.null(nrow(corr))){
    corr <- Matrix(corr, ncol = 2)
  }
  colnames(corr) <- c("corr_A", "corr_B") 
  corr
}
