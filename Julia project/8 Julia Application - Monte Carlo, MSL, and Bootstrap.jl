# Programming Languages: Session 4 -- Julia application companion script
#
# Julia Application: Monte Carlo, MSL, and Bootstrap
#
# Teaching use:
# This script is a slide companion. Comments carry the verbal slide content,
# and code blocks mirror slide code snippets in the same order.

# -----------------------------------------------------------------------------
# Section: Computational Statistics
# -----------------------------------------------------------------------------

# Slide: Monte Carlo Uses for Modelling
# (Visual slide)
# Image shown on slide: img/mcheuristics.png


# -----------------------------------------------------------------------------
# Section: Monte Carlo Methods
# -----------------------------------------------------------------------------

# Slide: Why Monte Carlo?
# For many non-trivial models, the distribution of epsilon mapped through the
# model's functional form M is not analytically tractable.
#
# M: epsilon -> y
#
# Even if it is tractable, the distribution may not be known, and so
# distributional properties like E[M(epsilon)] may not be available.
#
# E[M(epsilon)] = integral M(epsilon) f(epsilon) d epsilon
#
# Hence, simulate from f(epsilon) and apply M to approximate g(y) and compute
# empirical counterparts to desired distributional properties:
#
# (1 / N) * sum_{i=1}^N M(epsilon_i), where epsilon_i ~ f(epsilon)

# Slide: Simple MC Example
# Our "model" is y = M(epsilon) = epsilon^2, for which we have estimated
# epsilon ~ N(2, 1)
using Statistics

# Generate random draws
n_sims = 10_000

eps = randn(n_sims) .+ 2
eps
# Monte Carlo estimate
mc_estimate = mean(eps .^ 2)
println("MC estimate: ", mc_estimate)
println("True value: ", 5)

# Can you derive why the theoretical mean is 5 instead of 4?
# Hint: use a change of variables with the Jacobian,
# or the variance decomposition as a shortcut.

# Slide: Exercise: Expected Utility under Uncertainty
# Model: A consumer receives income y ~ Lognormal(mu = 1, sigma = 0.5).
# Utility function (CRRA):
# u(y) = y^(1 - gamma) / (1 - gamma), gamma != 1
# Task:
# 1. Simulate 100,000 draws from the income distribution.
# 2. Compute utility u(y) for each draw.
# 3. Estimate expected utility E[u(y)] using Monte Carlo integration.
# 4. Compare against closed-form solution:
#    E[u(y)] = (1 / (1 - gamma)) * exp((1 - gamma)*mu + 0.5*(1 - gamma)^2*sigma^2)

# SOLUTION: Expected Utility under Uncertainty
using Distributions, Random

# Set random seed for reproducibility
Random.seed!(42)

# Parameters
mu = 1.0
sigma = 0.5
gamma = 1.5  # CRRA coefficient (risk aversion parameter)
n_sims = 100_000

# 1. Simulate 100,000 draws from the income distribution
income_draws = rand(LogNormal(mu, sigma), n_sims)

# 2. Compute utility u(y) for each draw
# u(y) = y^(1 - gamma) / (1 - gamma)
utility_draws = income_draws .^ (1 - gamma) ./ (1 - gamma)

# 3. Estimate expected utility E[u(y)] using Monte Carlo integration
mc_estimate = mean(utility_draws)
mc_se = std(utility_draws) / sqrt(n_sims)  # Standard error

# 4. Compare against closed-form solution
# E[u(y)] = (1 / (1 - gamma)) * exp((1 - gamma)*mu + 0.5*(1 - gamma)^2*sigma^2)
closed_form = (1 / (1 - gamma)) * exp((1 - gamma) * mu + 0.5 * (1 - gamma)^2 * sigma^2)

# Print results
println("=" ^ 60)
println("Exercise: Expected Utility under Uncertainty (CRRA)")
println("=" ^ 60)
println("Parameters:")
println("  Income distribution: Lognormal(μ=$mu, σ=$sigma)")
println("  CRRA coefficient (γ): $gamma")
println("  Number of simulations: $n_sims")
println()
println("Results:")
println("  Monte Carlo estimate:    $mc_estimate")
println("  Standard error (MC):     $mc_se")
println("  Closed-form solution:    $closed_form")
println("  Absolute difference:     $(abs(mc_estimate - closed_form))")
println("  Relative error (%):      $(100 * abs(mc_estimate - closed_form) / closed_form)%")
println("=" ^ 60)


# -----------------------------------------------------------------------------
# Section: Maximum Simulated Likelihood
# -----------------------------------------------------------------------------

# Slide: Why Care About Intractable Likelihoods?
# - In your winter course on computational numerics, optimization is one of the
#   central topics.
# - Why? Because one of the key applications for numerical optimization is
#   maximizing (custom) likelihood functions.
# - But what if your likelihood is intractable, i.e., cannot be evaluated easily?
# - For dynamic models with Gaussian stochasticity, one approach is to linearize
#   while arguing similar dynamics in the linearized version.
# - Alternatively, tackle the intractability head-on.

# Slide: From Monte Carlo to Maximum Simulated Likelihood
# In many models, the likelihood involves an integral over unobserved variables
# (e.g., random effects, state space) that is not analytically tractable:
# L(theta) = product_i integral f(y_i | epsilon_i, theta) g(epsilon_i) d epsilon_i
#
# Replace the integral with a Monte Carlo average using R draws for each i:
# L_hat(theta) = product_i (1 / R) * sum_r f(y_i | epsilon_ir, theta)
#
# Simulate epsilon_ir ~ g(epsilon), compute f for each draw, average. Use this
# simulated likelihood in place of the true likelihood for estimation.

# Slide: MSL Demo: Measurement Model with Latent State
# y_i = x_i + epsilon_i, epsilon_i ~ N(0, 1), x_i ~ Exponential(lambda)
# Likelihood for observation i:
# L(y_i | lambda) = integral phi(y_i - x) * lambda * exp(-lambda * x) dx
# Simulated likelihood:
# L_hat(y_i | lambda) = (1 / R) * sum_r phi(y_i - x_i^(r)), x_i^(r) ~ Exp(lambda)
# (In this toy case, the integral also has a closed form.)

# Slide: MSL Implementation: Core Steps
using Distributions, Optim, Random

function simulated_likelihood(lambda, y_data; R = 1000)
    lambda <= 0 && return -Inf
    n = length(y_data)
    log_lik = 0.0

    for i in 1:n
        x_draws = rand(Exponential(1 / lambda), R)
        like_contr = pdf.(Normal(0, 1), y_data[i] .- x_draws)
        simulated_lik_i = mean(like_contr)
        log_lik += log(max(simulated_lik_i, 1e-10))
    end
    return log_lik
end

# Slide: MSL: Closed-Form Overlay Check
function closed_form_loglik(lambda, y_data)
    lambda <= 0 && return -Inf
    ll_i = lambda .* exp.(-lambda .* y_data .+ 0.5 * lambda^2) .*
           cdf.(Normal(), y_data .- lambda)
    return sum(log.(ll_i .+ 1e-12))
end

Random.seed!(42)
n = 500
lambda_true = 1.5
y = rand(Exponential(1 / lambda_true), n) .+ rand(Normal(), n)

obj_msl(lambda) = -simulated_likelihood(lambda, y; R = 2000)
obj_cf(lambda) = -closed_form_loglik(lambda, y)
lambda_msl = optimize(obj_msl, 1e-4, 5.0).minimizer
lambda_cf = optimize(obj_cf, 1e-4, 5.0).minimizer

println((lambda_true = lambda_true, lambda_msl = lambda_msl, lambda_closed_form = lambda_cf))

# Slide: Exercise: CRRA Utility with Unobserved Income
# Model: y ~ Lognormal(mu = 1, sigma = 0.5)
# Utility with measurement error:
# u(y, epsilon) = y^(1 - gamma) / (1 - gamma) + epsilon,
# gamma != 1, epsilon_i ~ N(0, 1)
# Intractable likelihood:
# L(gamma) = product_i integral phi(u_i - y^(1-gamma)/(1-gamma)) * f(y) dy
# Task: Implement MSL to estimate gamma given simulated data on utility {u_i}.

# SOLUTION: CRRA Utility with Unobserved Income
using Distributions, Optim, Random

function simulated_likelihood_crra(gamma, u_data; R = 1000, mu = 1.0, sigma = 0.5)
    gamma <= 0 && return -Inf
    gamma == 1 && return -Inf  # gamma != 1
    n = length(u_data)
    log_lik = 0.0

    for i in 1:n
        # Draw R samples from Lognormal(mu, sigma)
        y_draws = rand(LogNormal(mu, sigma), R)
        # Comput+e CRRA utility u(y) = y^(1 - gamma) / (1 - gamma)
        utility_draws = y_draws .^ (1 - gamma) ./ (1 - gamma)
        # Likelihood contribution: phi(u_i - u(y))
        like_contr = pdf.(Normal(0, 1), u_data[i] .- utility_draws)
        # Simulated likelihood for observation i
        simulated_lik_i = mean(like_contr)
        log_lik += log(max(simulated_lik_i, 1e-10))
    end
    return log_lik
end

# Generate simulated data
Random.seed!(42)
mu = 1.0
sigma = 0.5
gamma_true = 1.5
n = 500
R = 2000

# Simulate true utility from latent income
y_true = rand(LogNormal(mu, sigma), n)
u_true = y_true .^ (1 - gamma_true) ./ (1 - gamma_true)

# Add measurement error to create observed utility
u_data = u_true .+ rand(Normal(0, 1), n)

# MSL estimation
obj_msl(gamma) = -simulated_likelihood_crra(gamma, u_data; R = R, mu = mu, sigma = sigma)
gamma_msl = optimize(obj_msl, 0.5, 3.0).minimizer

# Results
println("=" ^ 60)
println("CRRA Utility with Unobserved Income - MSL Estimation")
println("=" ^ 60)
println("True gamma:              $gamma_true")
println("MSL estimate of gamma:   $gamma_msl")
println("Absolute difference:     $(abs(gamma_msl - gamma_true))")
println("=" ^ 60)


# -----------------------------------------------------------------------------
# Section: Bootstrapping
# -----------------------------------------------------------------------------

# Slide: Resampling Methods: Overview
# - Jackknife (1949): Leave one out at a time.
#   Key property on slide: efficient but needs smooth/linear estimators and
#   homoskedasticity.
# - Bootstrap (1979): Sample with replacement.
#   Key property on slide: most widely used; requires IID data and
#   homoskedasticity.
# - Subsampling (1994): Sample without replacement.
#   Key property on slide: allows non-IID data and heteroscedasticity, but less
#   efficient.
#
# Additional slide notes:
# - Plenty of other methods (wild bootstrap, block bootstrap, etc).
# - If analytical gradient is available, simplest thing is Delta Method.

# Slide: The Bootstrap Principle
# Goal: Approximate the sampling distribution of a parameter estimate theta_hat
# when population distribution F is unknown.
# Key idea: Use the empirical distribution F_hat (the sample) as a stand-in for F.
# Bootstrap algorithm:
# 1. Draw B bootstrap samples with replacement of size N from observed data.
# 2. Compute estimate theta_hat_b for each sample b = 1, ..., B.
# 3. Use the empirical distribution of {theta_hat_1, ..., theta_hat_B}
#    to approximate the sampling distribution of theta_hat.

# Slide: Demo: Bootstrapping MSL Estimates
# Problem: MSL estimates lambda_hat have unknown sampling distribution.
# Hessian-based CIs assume normality and may fail if likelihood is irregular.
#
# Bootstrap solution: Resample data, re-estimate lambda_hat many times.
#
# Normal-Exponential model:
# y_i = x_i + epsilon_i, epsilon_i ~ N(0,1), x_i ~ Exp(lambda)
#
# Bootstrap algorithm:
# 1. For b = 1, ..., B:
#    - Draw bootstrap sample {y_1^(b), ..., y_n^(b)} with replacement.
#    - Compute MSL estimate lambda_hat_b using simulated likelihood.
# 2. Use {lambda_hat_1, ..., lambda_hat_B} to construct confidence intervals.

# Slide: Demo: Bootstrapping MSL Estimates
using Base.Threads
nthreads()

# IMPORTANT: The Julia REPL is not designed for multi-threading and needs a little bit of help. 
# Open the settings json in VSCode and add:
#   "julia.NumThreads": "auto"
# Then restart the Julia REPL before running the threaded bootstrap code.

B = 200
R = 1000
lower = 1e-4
upper = 5.0
n = length(y)
boot_msl = Vector{Float64}(undef, B)
boot_cf = similar(boot_msl)
@threads for b in 1:B
    y_b = y[rand(1:n, n)]  # bootstrap sample with replacement
    obj_msl(lambda) = -simulated_likelihood(lambda, y_b; R = R)
    obj_cf(lambda) = -closed_form_loglik(lambda, y_b)
    boot_msl[b] = optimize(obj_msl, lower, upper).minimizer
    boot_cf[b] = optimize(obj_cf, lower, upper).minimizer
end

# Slide: Demo: Bootstrapping MSL Estimates (Run and Summary)
println((threads = nthreads(), mean_msl = mean(boot_msl), mean_cf = mean(boot_cf)))
println((sd_msl = std(boot_msl), sd_cf = std(boot_cf)))

# Script-only extension (not shown on slides): overlay bootstrap distributions
using Plots
histogram(boot_msl; bins = 25, normalize = :pdf, alpha = 0.45,
          label = "Bootstrap: MSL", xlabel = "lambda_hat", ylabel = "Density",
          title = "Bootstrap Distribution of lambda_hat")
histogram!(boot_cf; bins = 25, normalize = :pdf, alpha = 0.45,
           label = "Bootstrap: closed form")
vline!([mean(boot_msl)]; label = "mean MSL bootstrap", color = :blue, linestyle = :dash, linewidth = 2)
vline!([mean(boot_cf)]; label = "mean closed-form bootstrap", color = :green, linestyle = :dash, linewidth = 2)
vline!([lambda_true]; label = "true lambda", color = :red, linestyle = :solid, linewidth = 3)
