#standardSQL
# Correlation between Lighthouse preload-lcp-image audit and LCP

WITH lighthouse AS (
  SELECT
    IF(device = 'mobile', 'phone', 'desktop') AS device,
    SUBSTR(url, 0, LENGTH(url) - 1) AS origin,
    CAST(score AS FLOAT64) >= 0.9 AS is_passing
  FROM (
    SELECT
      _TABLE_SUFFIX AS device,
      url,
      JSON_EXTRACT_SCALAR(report, '$.audits.preload-lcp-image.score') AS score,
    FROM
      `httparchive.lighthouse.2022_10_01_*`
  )
  WHERE
    score IS NOT NULL
),

pages AS (
  SELECT
    device,
    origin,
    p75_lcp
  FROM
    `chrome-ux-report.materialized.device_summary`
  WHERE
    date = '2022-10-01' AND
    device IN ('desktop', 'phone')
)

SELECT
  device,
  is_passing,
  APPROX_QUANTILES(p75_lcp, 1000)[OFFSET(500)] AS median_p75_lcp,
  COUNT(0) AS freq
FROM
  pages
INNER JOIN
  lighthouse
USING
  (device, origin)
GROUP BY
  device,
  is_passing
ORDER BY
  device,
  is_passing
