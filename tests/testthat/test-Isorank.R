context("IsoRank")

# sample pair of graphs w. 10 vertices
set.seed(123)
cgnp_pair <- sample_correlated_gnp_pair(n = 10, corr =  0.3, p =  0.5)
A <- cgnp_pair$graph1
B <- cgnp_pair$graph2
startm <- matrix(0, 10, 10)
diag(startm)[1:4] <- 1
seeds<-1:4

test_that("matching correspondence between graph1 and graph2", {
  expect_equal(graph_match_IsoRank(A, B,startm, seeds,alpha = .3, method = "greedy")$corr,
               data.frame(corr_A = c(1:10), corr_B = c(1,2,3,4,9,6,10,8,5,7),row.names=as.character(1:10)))
})
test_that("order of nodes getting matched", {
  expect_equal(graph_match_IsoRank(A, B,startm,seeds, alpha = .3, method = "greedy")$order,
               c(1,2,3,4,6,10,8,7,5,9))
})
test_that("test number of seeds", {
  expect_equal(graph_match_IsoRank(A, B,startm, seeds,alpha = .3, method = "greedy")$ns,4)
})

