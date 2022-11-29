#standardSQL
# Top JS frameworks and libraries

SELECT 
  client,
  app,
  pages,
  total,
  pct
FROM (
  SELECT
    _TABLE_SUFFIX AS client,
    app,
    COUNT(DISTINCT url) AS pages,
    total,
    COUNT(DISTINCT url) / total AS pct,
    RANK() OVER (PARTITION BY _TABLE_SUFFIX ORDER BY COUNT(DISTINCT url) DESC) AS pop_rank
  FROM
    `httparchive.technologies.2022_10_01_*`
  JOIN (
    SELECT
      _TABLE_SUFFIX,
      COUNT(0) AS total
    FROM
      `httparchive.summary_pages.2022_10_01_*`
    GROUP BY
      _TABLE_SUFFIX
  )
  USING
    (_TABLE_SUFFIX)
  WHERE
    category IN ('JavaScript frameworks', 'JavaScript libraries')
  GROUP BY
    client,
    app,
    total
)
WHERE   
  pop_rank <= 10
ORDER BY
  client,
  pct DESC