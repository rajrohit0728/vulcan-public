AUDIT (
  name net_amount_consistency
);

-- Recomputes net_amount from quantity/unit_price/discount_pct and flags
-- drift beyond rounding tolerance — a live-data counterpart to
-- tests/test_int_order_lines_enriched.yaml's DuckDB unit test of the same
-- formula.
SELECT *
FROM @this_model
WHERE ABS(net_amount - (quantity * unit_price * (1 - discount_pct / 100.0))) > 0.01
