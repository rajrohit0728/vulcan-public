AUDIT (
  name no_negative_net_amount
);

SELECT * FROM @this_model WHERE net_amount < 0
