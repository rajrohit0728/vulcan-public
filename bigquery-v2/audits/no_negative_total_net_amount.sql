AUDIT (
  name no_negative_total_net_amount
);

SELECT * FROM @this_model WHERE total_net_amount < 0
