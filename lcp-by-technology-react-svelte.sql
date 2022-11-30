#standardSQL
# LCP for React and Svelte sites

CREATE TEMPORARY FUNCTION getGoodCwv(payload STRING)
RETURNS STRUCT<cumulative_layout_shift BOOLEAN, first_contentful_paint BOOLEAN, first_input_delay BOOLEAN, largest_contentful_paint BOOLEAN>
LANGUAGE js AS '''
try {
  var $ = JSON.parse(payload);
  var crux = $._CrUX;

  if (crux) {
    return Object.keys(crux.metrics).reduce((acc, n) => ({
      ...acc,
      [n]: crux.metrics[n].histogram[0].density > 0.75
    }), {})
  }

  return null;
} catch (e) {
  return null;
}
''';

WITH pages AS (
  SELECT
    _TABLE_SUFFIX AS device,
    url,
    getGoodCwv(payload) AS CrUX
  FROM
    `httparchive.pages.2022_10_01_*`
), 

technologies AS (
  SELECT
    _TABLE_SUFFIX AS device,
    app,
    url,
  FROM
    `httparchive.technologies.2022_10_01_*`
  WHERE
    app IN ('React', 'Svelte')
  GROUP BY
    device,
    app,
    url
)

SELECT
  device,
  app,
  COUNT(0) AS freq,
  COUNTIF(lcp) AS lcp_good,
  COUNTIF(lcp) / COUNT(0) AS pct_lcp_good,
FROM (
  SELECT
    pages.device AS device,
    app,
    CrUX.largest_contentful_paint AS lcp,
  FROM
    pages
  INNER JOIN
    technologies
  USING
    (device, url)
  WHERE
    CrUX IS NOT NULL
)
GROUP BY
  device,
  app
ORDER BY
  device,
  app
