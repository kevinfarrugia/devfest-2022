#standardSQL
# Top JS frameworks and libraries

WITH totals AS (
  SELECT
    _TABLE_SUFFIX,
    COUNT(0) AS total
  FROM
    `httparchive.summary_pages.2022_10_01_*`
  GROUP BY
    _TABLE_SUFFIX
)

SELECT 
  device,
  app,
  pages,
  total,
  pct
FROM (
  SELECT
    _TABLE_SUFFIX AS device,
    app,
    COUNT(DISTINCT url) AS pages,
    total,
    COUNT(DISTINCT url) / total AS pct,
    RANK() OVER (PARTITION BY _TABLE_SUFFIX ORDER BY COUNT(DISTINCT url) DESC) AS pop_rank
  FROM
    `httparchive.technologies.2022_10_01_*`
  JOIN 
    totals
  USING
    (_TABLE_SUFFIX)
  WHERE
    category IN ('JavaScript frameworks', 'JavaScript libraries')
  GROUP BY
    device,
    app,
    total
)
WHERE   
  pop_rank <= 10
ORDER BY
  device,
  pct DESC