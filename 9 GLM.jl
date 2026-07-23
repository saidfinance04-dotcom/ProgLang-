# Programming Languages: Session 5 -- GLM companion script
#
# GLM (Julia companion)
#
# Teaching use:
# This script is a slide companion. Comments carry the verbal slide content,
# and code blocks mirror slide code snippets in the same order.

# Required packages:
# import Pkg
# Pkg.add(["RDatasets", "DataFrames", "GLM", "StatsModels", "Optim"])

using RDatasets, DataFrames, GLM, StatsModels
using Optim, LinearAlgebra

# Shared dataset for the OLS and GLM examples below.
doc = dataset("Ecdat", "Doctor")

# -----------------------------------------------------------------------------
# 0. Overview
# -----------------------------------------------------------------------------

# Slide: Outline
# - OLS
# - MLE
# - GLM
# - Sandwich Estimator

# Slide: Session Scope and Historical Anchors
# - This session covers two very common model classes: GLM and tree-based
#   (bagging) machine learning models.
# - MLE and GLM are often the starting point for empirical projects, and many
#   structural papers begin with a reduced form to show that there is signal
#   in the data before moving on to a structural model.
# - We use the Doctor dataset to model doctor visits, access to care, and
#   health status as simple examples of count, binary, and continuous outcomes.
# - OLS: Legendre published the method of least squares in 1805; Gauss
#   independently derived and used least squares in 1809.
# - MLE: the modern maximum-likelihood framework is usually associated with
#   Fisher in the 1920s.
# - GLM: the generalized linear model framework was formalized by
#   Nelder and Wedderburn in 1972.
# - Sandwich / robust SEs: the basic robust-variance idea is associated with
#   Huber (1967) and White (1980).
# - In Julia, these workflows are typically handled with GLM.jl,
#   StatsModels.jl, and Optim.jl.

# Slide: OLS and Built-in GLM Specifications
# We use the Ecdat::Doctor dataset, a health-economics panel with doctor visits,
# access to care, children, and a continuous health score.

doc = dataset("Ecdat", "Doctor")

# Simple OLS
ols_model = lm(@formula(Health ~ Children + Access), doc)

# The same model can also be written via GLM:
glm(@formula(Health ~ Children + Access), doc, Normal(), IdentityLink())

doc.doctor_any = Float64.(doc.Doctor .> 0)
glm(@formula(doctor_any ~ Children + Access), doc, Binomial(), LogitLink())

glm(@formula(Doctor ~ Children + Access), doc, Poisson(), LogLink())


# -----------------------------------------------------------------------------
# 1. OLS
# -----------------------------------------------------------------------------

# Slide: OLS: Theory Refresher
# Model: y = X*beta + epsilon, where
# y in R^n, X in R^(n x k), beta in R^k, epsilon in R^n
# Assumptions:
# E[epsilon | X] = 0,
# Var(epsilon | X) = sigma^2 * I_n,
# rank(X) = k
#
# Table:
# - beta_hat_OLS = (X'X)^(-1) X'y
#   Var(beta_hat_OLS) = sigma^2 (X'X)^(-1)
# - sigma_hat^2 = (1 / (n-k)) * ||y - X*beta_hat_OLS||^2
#   Var(sigma_hat^2) = 2*sigma^4 / (n-k)
#
# In the class of unbiased linear predictors, beta_hat_OLS is most efficient
# by Gauss-Markov. Biased/non-linear estimators can still outperform OLS
# (James-Stein estimators).

# Slide: Exercise: Implement OLS From Scratch
# Task: Write a Julia function to estimate OLS coefficients and standard errors
# manually, using only matrix operations.
# - Use * for matrix multiplication.
# - Use A \ b to solve linear systems.
# - Use X' for matrix transpose.
# - Try to do everything vectorized (avoid for loops).
# - Return a named tuple with coefficients and standard errors.

# Slide: Exercise: OLS From Scratch (solution)
function ols_manual(y, X)
    n, k = size(X)

    beta_hat = (X' * X) \ (X' * y)

    residuals = y - X * beta_hat
    sigma2_hat = sum(residuals .^ 2) / (n - k)
    var_beta = sigma2_hat * ((X' * X) \ I(k))
    se_beta = sqrt.(diag(var_beta))

    return (coefficients = beta_hat, se = se_beta)
end

# Slide: OLS: Testing the Implementation
y = Float64.(doc.Health)
X = hcat(ones(nrow(doc)), Matrix(select(doc, [:Children, :Access])))

manual_result = ols_manual(y, X)
manual_beta = manual_result.coefficients

builtin_result = lm(@formula(Health ~ Children + Access), doc)
lm_beta = coef(builtin_result)

hcat(manual_beta, lm_beta)
hcat(manual_result.se, stderror(builtin_result))
maximum(abs.(manual_beta - lm_beta))


# -----------------------------------------------------------------------------
# 2. MLE
# -----------------------------------------------------------------------------

# Slide: From OLS to MLE: A Generalization
# OLS minimizes squared residuals:
# beta_hat_OLS = argmin_beta sum_i (y_i - x_i' * beta)^2
#
# If we assume Gaussian errors, then
#   epsilon_i ~ N(0, sigma^2) => y_i ~ N(x_i' * beta, sigma^2)
#
# then the likelihood is
#   L(beta) = product_i exp(-(y_i - x_i' * beta)^2 / (2*sigma^2))
# and the log-likelihood is
#   ell(beta) = -(1/(2*sigma^2)) * sum_i (y_i - x_i' * beta)^2
#
# Thus maximizing ell(beta) is equivalent to minimizing the OLS objective.
#
# MLE then generalizes this idea to any parametric density:
# theta_hat_MLE = argmax_theta sum_i log f(y_i | theta)

# Slide: MLE: Simple Normal Example
k = size(X, 2)
n = size(X, 1)

log_lik(params, y, X) = begin
    beta = params[1:k]
    sigma = params[k + 1]
    sigma <= 0 && return -Inf
    -0.5 * n * log(2 * pi) - n * log(sigma) -
        sum((y - X * beta) .^ 2) / (2 * sigma^2)
end

neg_log_lik(params, y, X) = -log_lik(params, y, X)

init_params = vcat(zeros(size(X, 2)), 1.0)
result = optimize(p -> neg_log_lik(p, y, X), init_params, BFGS())

# Slide: MLE: Standard Errors

# Extract optimizer results
theta_hat = Optim.minimizer(result)
beta_hat = theta_hat[1:k]

# IMPORTANT: this is the MLE sigma from the optimizer.
# It is biased in small samples because it does NOT apply the
# usual n/(n-k) correction that you may know from OLS.
# OLS and MLE for the linear-Gaussian model are equivalent in the asymptotic limit that MLE imposes.
sigma_hat = theta_hat[end]
sigma_corrected = sigma_hat * sqrt(n / (n - k))

builtin_normal = lm(@formula(Health ~ Children + Access), doc)
builtin_beta = coef(builtin_normal)

hcat(vcat(beta_hat, sigma_hat), vcat(builtin_beta, sigma_corrected))

# The manual MLE parameters line up with the built-in OLS estimates.


# Slide: Exercise: MLE for the Laplace Distribution

# Task: Estimate Laplace parameters via MLE.
# Laplace density:

# f(y | mu, b) = (1 / (2b)) * exp(-|y - mu| / b)
# Likelihood for y_1,...,y_n:
# L(mu, b) = product_i (1/(2b)) * exp(-|y_i - mu|/b)

# Log-likelihood:
# ell(mu,b) = -n*log(2b) - (1/b) * sum_i |y_i - mu|

# Estimate reparameterized mean mu = X*beta and scale b > 0.
# Use optimize() on the health outcome Health with Children and Access as
# predictors.

# SOLUTION: MLE for the Laplace Distribution
function log_lik_laplace(params, y, X)
    beta = params[1:(size(X, 2))]
    b = params[end]
    b <= 0 && return -Inf
    
    mu = X * beta
    n = length(y)
    -n * log(2 * b) - (1 / b) * sum(abs.(y - mu))
end

neg_log_lik_laplace(params, y, X) = -log_lik_laplace(params, y, X)

# Use the same y and X from OLS examples
init_params = vcat(zeros(size(X, 2)), 1.0)
result_laplace = optimize(p -> neg_log_lik_laplace(p, y, X), init_params, BFGS())

beta_laplace = Optim.minimizer(result_laplace)[1:(size(X, 2))]
b_laplace = Optim.minimizer(result_laplace)[end]

println("=" ^ 60)
println("Laplace MLE Results")
println("=" ^ 60)
println("Beta coefficients: ", beta_laplace)
println("Scale parameter b: ", b_laplace)
println("=" ^ 60)


# -----------------------------------------------------------------------------
# 3. GLM
# -----------------------------------------------------------------------------

# Slide: MLE: Logistic Regression Motivation
# Binary outcome: y_i in {0,1} => y_i ~ Bernoulli(p_i)
# Link:
# p_i = 1 / (1 + exp(-x_i' * beta))
#
# Likelihood:
# L(beta) = product_i [p_i^y_i * (1-p_i)^(1-y_i)]
#
# No closed form: maximize log-likelihood numerically (e.g., BFGS).

# Slide: MLE: Logistic Regression from Scratch
log_lik_logit(beta, y, X) = begin
    linear_pred = X * beta
    prob = 1.0 ./ (1.0 .+ exp.(-linear_pred))
    prob = clamp.(prob, 1e-12, 1 - 1e-12)
    sum(y .* log.(prob) + (1 .- y) .* log.(1 .- prob))
end

neg_log_lik_logit(beta, y, X) = -log_lik_logit(beta, y, X)

y_logit = doc.doctor_any
mle_logit = optimize(
    b -> neg_log_lik_logit(b, y_logit, X),
    zeros(k),
    BFGS(),
)

# Built-in logit fit for comparison.
builtin_logit = glm(@formula(doctor_any ~ Children + Access), doc, Binomial(), LogitLink())
logit_beta = coef(builtin_logit)

hcat(Optim.minimizer(mle_logit), logit_beta)

# Slide: Exercise: Poisson Regression
# What if the outcome is a count? y_i in {0,1,2,...} => y_i ~ Poisson(lambda_i)
# Link:
# lambda_i = exp(x_i' * beta)
#
# Likelihood:
# L(beta) = product_i [lambda_i^y_i * exp(-lambda_i) / y_i!]
#
# Log-likelihood:
# ell(beta) = sum_i [y_i * x_i' * beta - exp(x_i' * beta) - log(y_i!)]
#
# No closed form: maximize log-likelihood numerically (e.g., BFGS).
# Apply this to Doctor: model the number of doctor visits with Children and
# Health as predictors.
using SpecialFunctions: loggamma: gammaimport Pkg; Pkg.add("SpecialFunctions")show(err)