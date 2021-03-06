% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/splr_matrix_class.R
\docType{class}
\name{splrMatrix-class}
\alias{splrMatrix-class}
\title{splrMatrix class definition}
\arguments{
\item{x}{a sparse matrix}

\item{a}{a low-rank factor or a matrix}

\item{b}{optional. a low-rank factor for \code{a \%*\% t(b)}. if \code{b} is not provided, a will be factorized using 
\code{irlba} provided \code{factorize = TRUE}}

\item{rank}{the estimated rank of the matrix to be factorized.  If \code{rank} is not provided, a guess is made}

\item{tol}{the tolerance for the eigenvalues if \code{rank} is not provided}

\item{dimnames}{optional - the list of names for the matrix}

\item{factorize}{a safeguard to prevent unnecessary computation (e.g. if the matrix is very large).  If \code{a} 
is provided and \code{factorize = FALSE}, an error will result.}
}
\description{
stores sparse plus low-rank matrices (e.g. from matrix factorization or centering graphs) of the form
\code{x + a \%*\% t(b)} for faster computation
}
