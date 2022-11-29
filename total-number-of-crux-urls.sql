#standardSQL
# Total number of distinct URLs in the dataset (mobile)

SELECT
  _TABLE_SUFFIX AS client,
  COUNT(DISTINCT url) AS total
FROM
  `httparchive.urls.latest_crux_*`
GROUP BY
  client
