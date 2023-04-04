DROP MATERIALIZED VIEW if EXISTS ps.acp_participating_aiannh;
CREATE MATERIALIZED VIEW ps.acp_participating_aiannh AS (

WITH acp_zip_data AS (SELECT
  zs.state_id AS state_id,

  CASE
    WHEN dt.zip_code ISNULL
      THEN mt.zip_code
    ELSE dt.zip_code END AS zip_code,
    
  CASE
    WHEN dt.date ISNULL
      THEN (DATE_TRUNC('month', mt.date) + interval '1 month' - interval '1 day')::date
    ELSE (DATE_TRUNC('month', dt.date) + interval '1 month' - interval '1 day')::date END AS date,
  CASE
    WHEN dt.total_subscribers ISNULL
      THEN mt.enrolled_households
    ELSE dt.total_subscribers END AS acp_enrolled
    

FROM
  dl.acp_zip_detail dt

  FULL OUTER JOIN dl.acp_zip_monthly mt
  ON dt.zip_code = mt.zip_code
  AND (DATE_TRUNC('month', dt.date) + interval '1 month' - interval '1 day')::date = (DATE_TRUNC('month', 
mt.date) + interval '1 month' - interval '1 day')::date
  FULL OUTER JOIN dl.crosswalk_zip_state_geocorr zs
  ON dt.zip_code=zs.zip
)

SELECT 
    dt.state_id,    
    cw.zip AS zip_code,
    cw.aiannh_code,
    dt.date,
    SUM(dt.acp_enrolled*cw.allocation_factor) AS acp_enrolled
   

FROM dl.crosswalk_zip_aiannh_geocorr cw
JOIN acp_zip_data dt
     ON cw.zip=dt.zip_code

GROUP BY
    dt.state_id,    
    cw.zip,
    cw.aiannh_code,
    dt.date
);

