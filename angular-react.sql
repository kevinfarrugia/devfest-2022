#standardSQL
# Websites using both AngularJS and React

WITH totals AS (
  SELECT
    _TABLE_SUFFIX,
    COUNT(0) AS total
  FROM
    `httparchive.summary_pages.2022_10_01_*`
  GROUP BY
    _TABLE_SUFFIX
),
  
technologies AS (
  SELECT
    _TABLE_SUFFIX AS device,
    url AS page,
    total,
    ARRAY_TO_STRING(ARRAY_AGG(app ORDER BY app), ', ') AS apps
  FROM
    `httparchive.technologies.2022_10_01_*`
  JOIN
    totals
  USING
    (_TABLE_SUFFIX)
  WHERE
    app = 'AngularJS' OR
    app = 'React'
  GROUP BY
    device,
    url,
    total
)

SELECT
  device,
  apps,
  COUNT(DISTINCT page) AS pages,
  total,
  COUNT(DISTINCT page) / total AS pct
FROM 
  technologies
GROUP BY
  device,
  apps,
  total
ORDER BY
  pct DESC
