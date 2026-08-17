"""
Custom linter rules for abfss-spark-dp.

These class names are referenced by `config.yaml > linter.warn_rules`. Vulcan
auto-discovers subclasses of `vulcan.Rule` found in this package on startup.
"""

import typing as t

try:
    from vulcan import Rule, RuleViolation, Model
except ImportError:  # pragma: no cover - import shim for non-Vulcan environments
    Rule = object
    RuleViolation = None
    Model = None


# Kinds that don't materialize tabular data and therefore can't meaningfully
# carry a grain, an owner, assertions, or a matching dq suite:
#   - external / seed  : source declarations / static CSV loads
#   - metric / dq / audit / semantic / metric_view / semantic_view : definitions,
#     not physical tables
_NON_MATERIALIZING_KINDS = {
    "external",
    "metric",
    "dq",
    "audit",
    "seed",
    "metric_view",
    "semantic_view",
    "semantic",
}


def _should_skip(model: "Model") -> bool:
    """Return True when the model isn't a materialized data model."""
    kind = str(getattr(model, "kind", "") or "").lower()
    if not kind:
        return False
    return any(non_mat in kind for non_mat in _NON_MATERIALIZING_KINDS)


class RequireGrainForAllModels(Rule):
    """Every materialized model must declare a grain (or grains)."""

    def check_model(self, model: "Model") -> t.Optional["RuleViolation"]:
        if _should_skip(model):
            return None
        grain = getattr(model, "grain", None) or getattr(model, "grains", None)
        if not grain:
            return self.violation(
                "\nAll models must define a grain for data quality assurance.\n"
            )
        return None


class RequireOwnerForAllModels(Rule):
    """Every materialized model must declare an owner."""

    def check_model(self, model: "Model") -> t.Optional["RuleViolation"]:
        if _should_skip(model):
            return None
        if not getattr(model, "owner", None):
            return self.violation("\nAll models must declare an owner.\n")
        return None


class RequireAssertionsForAllModels(Rule):
    """Every materialized model must carry assertions (built-in checks and/or custom audits)."""

    def check_model(self, model: "Model") -> t.Optional["RuleViolation"]:
        if _should_skip(model):
            return None
        # "assertions (...)" compiles onto the model as `audits` internally;
        # check both names defensively across vulcan versions.
        has_assertions = getattr(model, "audits", None) or getattr(model, "assertions", None)
        if not has_assertions:
            return self.violation(
                "\nAll models must define assertions (checks and/or audits).\n"
            )
        return None


class RequireDqForMartModels(Rule):
    """Every mart.* model must have a matching kind: dq suite."""

    def check_model(self, model: "Model") -> t.Optional["RuleViolation"]:
        if _should_skip(model):
            return None
        name = str(getattr(model, "name", "") or "")
        if ".mart_v4_vnew." not in name and ".mart." not in name:
            return None
        if getattr(model, "dq", None) is None:
            return self.violation(
                f"\nMart model '{name}' must have a matching dq/*.yml suite.\n"
            )
        return None
