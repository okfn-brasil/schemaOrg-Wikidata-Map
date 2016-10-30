--
-- stpe2
--

-- Before copy by shell: COPY wd2schema_std_temp FROM STDIN CSV HEADER

-- Adapat to better structure:
CREATE TABLE wd2schema_std AS
  SELECT
    COALESCE(equivclass,equivprop,sub,super) as sch_id,
    CASE
        WHEN equivclass IS NOT NULL THEN 'equivclass'
        WHEN equivprop IS NOT NULL THEN 'equivprop'
        WHEN sub IS NOT NULL THEN 'sub'
        WHEN super IS NOT NULL THEN 'super'
    END as reltype,
    p As wd_id,
    plabel as wd_label
  FROM wd2schema_std_temp
;
CREATE VIEW vw_wd2schema_std AS
  SELECT *, reltype='equivprop' as rel_isprop,
        ascii(substring(sch_id,1,1)::char)>87 as sch_isprop,
        substring(wd_id,1,1)='P' wd_isprop
  FROM wd2schema_std
  ORDER BY sch_id,reltype
;
DROP TABLE wd2schema_std_temp;

-- Clean:
UPDATE wd2schema_std SET
   wd_id  = regexp_replace(wd_id,  '^https?://[a-z\.]+/?', ''),
   sch_id = regexp_replace(sch_id, '^https?://[a-z\.]+/?', '')
;

-- Back as new file: see copy by shell
--  COPY (SELECT * FROM wd2schema_std ORDER BY sch_id,reltype) TO STDOUT WITH CSV HEADER;
