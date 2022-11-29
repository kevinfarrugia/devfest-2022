#standardSQL
# Correlation between the number of preload hints and LCP

CREATE TEMPORARY FUNCTION getResourceHints(payload STRING)
RETURNS STRUCT<preload INT64, prefetch INT64, preconnect INT64, prerender INT64, `dns-prefetch` INT64, `modulepreload` INT64>
LANGUAGE js AS '''
var hints = ['preload'];
try {
  var $ = JSON.parse(payload);
  var almanac = JSON.parse($._almanac);
  return hints.reduce((results, hint) => {
    // Null values are omitted from BigQuery aggregations.
    // This means only pages with at least one hint are considered.
    results[hint] = almanac['link-nodes'].nodes.filter(link => link.rel.toLowerCase() == hint).length || 0;
    return results;
  }, {});
} catch (e) {
  return hints.reduce((results, hint) => {
    results[hint] = 0;
    return results;
  }, {});
}
''';

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
    getResourceHints(payload) AS hints,
    getGoodCwv(payload) AS CrUX
  FROM
    `httparchive.pages.2022_10_01_*`
)

SELECT
  device,
  LEAST(preload, 30) AS preload,
  COUNT(0) AS freq,
  SUM(COUNT(0)) OVER (PARTITION BY device) AS total,
  COUNTIF(lcp) AS lcp_good,
  COUNTIF(lcp) / COUNTIF(lcp IS NOT NULL) AS pct_lcp_good,
FROM (
  SELECT
    device,
    hints.preload AS preload,
    CrUX.largest_contentful_paint AS lcp,
  FROM 
    pages
  WHERE
    hints.preload > 0 AND
    CrUX IS NOT NULL
)
GROUP BY
  device,
  preload
ORDER BY
  device,
  preload
