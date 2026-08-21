AUDIT (
  name no_negative_quantity
);

SELECT * FROM @this_model WHERE quantity < 0
