DROP MATERIALIZED VIEW if EXISTS ps.acp_participating_aiannh;
CREATE MATERIALIZED VIEW ps.acp_participating_aiannh AS (

WITH acp_county_data AS (SELECT
  CASE
    WHEN dt.state_id ISNULL
      THEN mt.state_id
    ELSE dt.state_id END AS state_id,
    
  CASE 
    WHEN dt.state_id ISNULL
      THEN CONCAT(mt.state_id,mt.county_id)
    ELSE CONCAT(dt.state_id,dt.county_id) END AS county_id, 
    
  CASE
    WHEN dt.date ISNULL
      THEN (DATE_TRUNC('month', mt.date) + interval '1 month' - interval '1 day')::date
    ELSE (DATE_TRUNC('month', dt.date) + interval '1 month' - interval '1 day')::date END AS date,
  CASE
    WHEN dt.total_subscribers ISNULL
      THEN mt.enrolled_households
    ELSE dt.total_subscribers END AS acp_enrolled

FROM
  dl.acp_county_detail dt

  FULL OUTER JOIN dl.acp_county_monthly mt
  ON dt.state_id = mt.state_id
  AND dt.county_id = mt.county_id
  AND (DATE_TRUNC('month', dt.date) + interval '1 month' - interval '1 day')::date = (DATE_TRUNC('month', mt.date) + interval '1 
month' - interval '1 day')::date
)

SELECT 
    dt.state_id,    
    cw.county_id,
    cw.aiannh_code,
    dt.date,
    SUM(dt.acp_enrolled*cw.allocation_factor) AS acp_enrolled
   

FROM dl.crosswalk_county_aiannh_geocorr cw
JOIN acp_county_data dt
     ON cw.county_id=dt.county_id

GROUP BY
    dt.state_id,    
    cw.county_id,
    cw.aiannh_code,
    dt.date   
);
