# Companion script for Session 5: Bagging.
#
# Goal:
# This file is a slide companion with both runnable code and verbal teaching
# content from active slides.

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

import rdatasets
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error
from sklearn.linear_model import LinearRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.neural_network import MLPRegressor
from sklearn.tree import DecisionTreeRegressor, plot_tree
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor

# -----------------------------------------------------------------------------
# 1) Motivation / Setup
# -----------------------------------------------------------------------------

# Slide: Why Machine Learning?
# - If a model is meant to be interpreted causally, then unbiased and
#   consistent parameters are usually desirable.
# - If the goal is predictive accuracy, unbiasedness and consistency are no
#   longer the only relevant criteria.
# - The James-Stein insight is that biased estimators can outperform unbiased
#   ones for prediction tasks.
# - So the main criterion shifts from unbiasedness / consistency to low
#   out-of-sample risk.
# - We therefore evaluate the models in this lecture on holdout data and focus
#   on predictive power.

# Slide: Prediction Context: Health Status in the Doctor Dataset
# - We use the Doctor dataset from Ecdat, also used in the earlier GLM lecture.
# - It contains a cross-section of 485 individuals in the United States in 1986.
# - Outcome is health: a numeric health-status measure for which larger values
#   indicate poorer health.
# - Covariates are doctor visits, number of children, and access to health care.
# - Goal is predictive accuracy, not causal interpretation.
# - We use the same split to compare a linear baseline with flexible ML models
#   cleanly.

# Slide: Setup and Linear Regression Baseline (data setup block)
doctor_data = rdatasets.data("Ecdat", "Doctor")

X = doctor_data[["doctor", "children", "access"]]
y = doctor_data["health"]

Xtr, Xte, ytr, yte = train_test_split(
    X, y, test_size=0.2, random_state=42
)
Xtr, Xte, ytr, yte
results = {}

# Slide: Setup and Linear Regression Baseline (linear model block)
linear = LinearRegression()
linear.fit(Xtr, ytr)

pred_tr = linear.predict(Xtr)
pred_te = linear.predict(Xte)

results["Linear regression"] = {
    "Train MAE": mean_absolute_error(ytr, pred_tr),
    "Test MAE": mean_absolute_error(yte, pred_te),
}

results["Linear regression"]

# Slide: Machine Learning in This Lecture
# - Linear regression is a strong baseline, but its predictor can be very
#   restrictive.
# - Think of ML models as flexible function approximators:
#   y_i = f(x_i) + eps_i
# - The object we estimate is usually f-hat = argmin over a function class.
# - Linear regression chooses a structured parametric function class.
# - ML often chooses a much richer class: neural nets, trees, forests.
# - Much of introductory ML is essentially "glorified curve fitting"
#   (Judea Pearl, 2018).
# - We compare models using mean absolute error (MAE): on average, how far is
#   the predicted health score from the observed health score?


# -----------------------------------------------------------------------------
# 2) Neural Networks
# -----------------------------------------------------------------------------

# Slide: A Minimal Neural Network
# One hidden layer regression model:
#   h = sigma(W1 x + b1), y_hat = W2 h + b2
# Parameters are trained by minimizing prediction error.

# Slide: Neural Network in scikit-learn
mlp = Pipeline([
    ("scale", StandardScaler()),
    ("model", MLPRegressor(
        hidden_layer_sizes=(16,),
        solver="lbfgs",
        max_iter=5000,
        random_state=42,
    )),
])
mlp.fit(Xtr, ytr)

pred_tr = mlp.predict(Xtr)
pred_te = mlp.predict(Xte)

results["Neural network"] = {
    "Train MAE": mean_absolute_error(ytr, pred_tr),
    "Test MAE": mean_absolute_error(yte, pred_te),
}

results["Neural network"]

# -----------------------------------------------------------------------------
# 3) Decision Trees
# -----------------------------------------------------------------------------

# Slide: Decision Trees: Basic Idea
# Tree partitions the covariate space into regions and predicts piecewise
# constants. Splits are chosen to reduce impurity/loss.

# Slide: Decision Tree in scikit-learn
tree = DecisionTreeRegressor(max_depth=3, random_state=42)
tree.fit(Xtr, ytr)

pred_tr = tree.predict(Xtr)
pred_te = tree.predict(Xte)

results["Decision tree"] = {
    "Train MAE": mean_absolute_error(ytr, pred_tr),
    "Test MAE": mean_absolute_error(yte, pred_te),
}

results["Decision tree"]

plt.figure(figsize=(24, 12))
plot_tree(tree, feature_names=X.columns, filled=True, max_depth=3)
plt.title("Decision tree for predicted health status")
plt.show()


# -----------------------------------------------------------------------------
# 4) Random Forests
# -----------------------------------------------------------------------------

# Slide: Random Forests: Basic Idea
# Random forests average many decorrelated trees to reduce variance.

# Slide: Random Forest in scikit-learn
forest = RandomForestRegressor(
    n_estimators=300,
    max_features="sqrt",
    min_samples_leaf=4,
    random_state=42,
)
forest.fit(Xtr, ytr)

pred_tr = forest.predict(Xtr)
pred_te = forest.predict(Xte)

results["Random forest"] = {
    "Train MAE": mean_absolute_error(ytr, pred_tr),
    "Test MAE": mean_absolute_error(yte, pred_te),
}

results["Random forest"]

importance = pd.Series(
    forest.feature_importances_, index=X.columns
).sort_values(ascending=False)
print("\nRandom forest feature importance:")
print(importance)

# Slide: Comparing Predictive Accuracy
comparison = pd.DataFrame(results).T
comparison.index.name = "Model"

print("\nMean absolute error: lower values are better.")
print(comparison.round(3))
