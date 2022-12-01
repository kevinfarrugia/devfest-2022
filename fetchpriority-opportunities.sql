#standardSQL
# fetchpriority opportunities
# - when there is more than one render-blocking request AND
# - when there is render-blocking JavaScript AND
# - LCP is image

CREATE TEMPORARY FUNCTION getRenderBlockingScripts(payload STRING)
RETURNS INT64
LANGUAGE js AS '''
try {
  var $ = JSON.parse(payload);
  var renderBlockingJS = $._renderBlockingJS;
  return renderBlockingJS;
} catch (e) {
  return 0;
}
''';


CREATE TEMPORARY FUNCTION getRenderBlockingStylesheets(payload STRING)
RETURNS INT64
LANGUAGE js AS '''
try {
  var $ = JSON.parse(payload);
  var renderBlockingCSS = $._renderBlockingCSS;
  return renderBlockingCSS;
} catch (e) {
  return 0;
}
''';

WITH render_blocking_resources AS (
  SELECT
    _TABLE_SUFFIX AS device,
    url,
    getRenderBlockingScripts(payload) AS number_of_render_blocking_scripts,
    getRenderBlockingStylesheets(payload) AS number_of_render_blocking_stylesheets,
    JSON_EXTRACT_SCALAR(payload, '$._performance.lcp_elem_stats.nodeName') AS lcpNodeName
  FROM
    `httparchive.pages.2022_10_01_*`
)

SELECT
  device,
  COUNTIF(
    number_of_render_blocking_scripts > 0 AND 
    number_of_render_blocking_scripts + number_of_render_blocking_stylesheets > 1
  ) AS is_opportunity,
  COUNT(0) AS total_pages,
  COUNTIF(
    number_of_render_blocking_scripts > 0 AND 
    number_of_render_blocking_scripts + number_of_render_blocking_stylesheets > 1
  ) / COUNT(0) AS pct_pages_with_opportunity
FROM
  render_blocking_resources
WHERE
  lcpNodeName = 'IMG'
GROUP BY
  device
