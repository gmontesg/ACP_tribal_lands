DROP MATERIALIZED VIEW if EXISTS ps.acp_eligible_aiannh;
CREATE MATERIALIZED VIEW ps.acp_eligible_aiannh AS (


WITH household_eligibility AS (SELECT
    hh.state_id,
    hh.puma_id,
    hh.serialno,
    MAX(CASE
      WHEN pop.hins4 = '1' OR hh.fs = '1' OR pop.pap > 0 OR pop.ssip > 0 OR pop.povpip <= 200
        THEN hh.wgtp
      ELSE 0 END) AS acp_eligible,
    CASE
      WHEN accessinet = '3'
        THEN TRUE
      ELSE FALSE END AS no_internet,
    CASE
      WHEN accessinet = '1' AND hispeed = '2' AND othsvcex = '2' AND dialup = '2' AND satellite = '2'
        THEN TRUE
      ELSE FALSE END AS cell_internet_only,
    CASE
      WHEN accessinet = '1' AND hispeed = '2' AND othsvcex = '2' AND dialup = '1' AND satellite = '2'
        THEN TRUE
      ELSE FALSE END AS dial_up_only


  FROM
    dl.pums_households_2020 hh

    LEFT JOIN dl.pums_population_2020 pop
    ON hh.puma_id = pop.puma_id
    AND hh.serialno = pop.serialno

  GROUP BY
    hh.state_id,
    hh.puma_id,
    hh.serialno,
    hh.accessinet,
    hh.hispeed,
    hh.othsvcex,
    hh.dialup,
    hh.satellite
)

SELECT 
  cpa.state_id,
  cpa.aiannh_code,
  SUM(he.acp_eligible * cpa.allocation_factor) AS households_acp_eligible,
  SUM(he.acp_eligible * cpa.allocation_factor) FILTER (WHERE he.no_internet = TRUE OR he.cell_internet_only = TRUE OR 
he.dial_up_only = TRUE) AS households_acp_eligible_unconnected


FROM dl.crosswalk_puma_aiannh_geocorr cpa

JOIN household_eligibility he
ON cpa.puma_id=he.puma_id
AND cpa.state_id=he.state_id

GROUP BY
 cpa.state_id,
 cpa.aiannh_code
    
);
