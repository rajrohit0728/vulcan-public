"""
Reusable SQL macros for the abfss-spark-dp project (Spark dialect).

Invoked inside SQL models with @macro_name(...) syntax.
"""

from vulcan import macro


@macro()
def net_amount(evaluator, quantity, unit_price, discount_pct):
    """Line-item revenue after a percentage discount: quantity * unit_price * (1 - discount_pct / 100)."""
    return f"({quantity} * {unit_price}) * (1 - {discount_pct} / 100.0)"


@macro()
def order_value_tier(evaluator, amount_col):
    """Classify a line item's net_amount into value tiers."""
    return f"""CASE
        WHEN {amount_col} >= 300 THEN 'premium'
        WHEN {amount_col} >= 100 THEN 'standard'
        WHEN {amount_col} >= 30 THEN 'basic'
        ELSE 'micro'
    END"""
