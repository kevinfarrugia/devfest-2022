WITH pages AS (
  SELECT
    _TABLE_SUFFIX AS client,
    CAST(JSON_VALUE(payload, '$._metadata.page_id') AS INT64) AS pageid,
    JSON_VALUE(payload, '$._performance.lcp_elem_stats.url') AS url
  FROM
    `httparchive.pages.2022_10_01_*`
),

requests AS (
  SELECT
    _TABLE_SUFFIX AS client,
    pageid,
    url,
    format
  FROM
    `httparchive.summary_requests.2022_10_01_*`
  WHERE
    format = "jpg"
)

SELECT
  url
FROM
  pages
JOIN
  requests
USING
  (client, pageid, url)
LIMIT 100