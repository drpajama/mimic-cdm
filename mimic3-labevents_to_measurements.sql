CREATE OR REPLACE FUNCTION is_number(prm_str text) RETURNS BOOLEAN AS $$
DECLARE
  v_return BOOLEAN;
BEGIN
  IF regexp_matches(prm_str,E'^-*[[:digit:]]+\.?[[:digit:]]+$') is not null 
  THEN
     v_return = TRUE;
  ELSE
    v_return = FALSE;
  END IF;
  RETURN v_return;     
END;
$$ LANGUAGE 'plpgsql';



truncate table ohdsi.measurement;
INSERT INTO ohdsi.measurement (measurement_id, person_id, measurement_concept_id, measurement_date, measurement_time, measurement_type_concept_id, 
	operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, provider_id, visit_occurrence_id, measurement_source_value, measurement_source_concept_id, 
	unit_source_value, value_source_value)
SELECT 
	temp_table.measurement_id,
	temp_table.person_id, 
	temp_table.concept_id as measurement_concept_id,
	temp_table.measurement_date,
	temp_table.measurement_time,
	temp_table.measurement_type_concept_id,
	temp_table.operater_concept_id,
	temp_table.value_as_number,
	temp_table.value_as_concept_id,
  CASE
	WHEN unit_concept.concept_id IS NOT NULL THEN unit_concept.concept_id
	WHEN LOWER(temp_table.valueuom) = 'mm hg' OR LOWER(temp_table.valueuom) = 'mmhg' 
		OR temp_table.loinc_code = '19991-9' THEN 8876 -- UCUM Code for millimeter mercury column
	WHEN LOWER(temp_table.valueuom) = 'meq/l' THEN 9557
	WHEN temp_table.valueuom = '%' THEN 8554
	WHEN LOWER(temp_table.valueuom) = 'meq/l' THEN 9557
	WHEN LOWER(temp_table.valueuom) = 'mg/dl' THEN 8840
	WHEN LOWER(temp_table.valueuom) = 'g/dl' THEN 8713
	WHEN LOWER(temp_table.valueuom) = 'mmol/l' THEN 8753
	WHEN LOWER(temp_table.valueuom) = 'l/min' THEN 8698
	WHEN temp_table.loinc_code ='11558-4' OR temp_table.loinc_code ='2748-2' THEN 8482  -- 11558-4 is LOINC code for pH. 8482 if UCUM code for pH
	WHEN LOWER(temp_table.valueuom) = 'iu/l' THEN 8923
	WHEN LOWER(temp_table.valueuom) = 'ug/ml' THEN 8859
	WHEN LOWER(temp_table.valueuom) = 'ng/ml' THEN 8842
	WHEN LOWER(temp_table.valueuom) = 'umol/l' THEN 8749
	WHEN LOWER(temp_table.valueuom) = 'iu/ml' THEN 8985
	WHEN LOWER(temp_table.valueuom) = 'u/ml' THEN 8763
	WHEN LOWER(temp_table.valueuom) = 'ratio' THEN 8523
	WHEN LOWER(temp_table.valueuom) = 'ug/dl' THEN 8837
	WHEN LOWER(temp_table.valueuom) = 'pg/ml' THEN 8845
	WHEN LOWER(temp_table.valueuom) = 'miu/l' THEN 9040
	WHEN LOWER(temp_table.valueuom) = 'miu/ml' THEN 9550
	WHEN LOWER(temp_table.valueuom) = 'units' THEN 8510
	WHEN LOWER(temp_table.valueuom) = 'uiu/l' THEN 44777583
	WHEN LOWER(temp_table.valueuom) = 'uiu/ml' THEN 9093
	WHEN LOWER(temp_table.valueuom) = 'uu/ml' THEN 9093 -- uIU/mL
	WHEN LOWER(temp_table.valueuom) = 'mg/24hr' THEN 8909 
	WHEN LOWER(temp_table.valueuom) = 'u/l' THEN 8645 
	WHEN LOWER(temp_table.valueuom) = 'ml/min' THEN 8795 
	WHEN LOWER(temp_table.valueuom) = '#/cu mm' THEN 8785 -- per cubic millimeter [for WBC or RBC in peritoneal fluid] 
	WHEN LOWER(temp_table.valueuom) = '#/uL' THEN 8647
	WHEN LOWER(temp_table.valueuom) = 'gpl' THEN 4171221
	WHEN LOWER(temp_table.valueuom) = 'score' and temp_table.loinc_code = '15112-6' THEN 4196800 -- SNOMED code for Leukocyte alkaline phosphatase score (class: procedure) 
	WHEN LOWER(temp_table.valueuom) = '/mm3' THEN 8785
	WHEN LOWER(temp_table.valueuom) = 'sec' OR LOWER(temp_table.valueuom) = 'seconds' THEN 8555
	WHEN LOWER(temp_table.valueuom) = 'serum vis' THEN 3010493 -- LOINC code for Viscosity of Serum
	WHEN LOWER(temp_table.valueuom) = 'eu/dl' THEN 8829
	WHEN LOWER(temp_table.valueuom) = 'mm/hr' THEN 8752
	ELSE 0
  END as unit_concept_id,
   0 as provider_id,
   visit_occurence_id,
   measurement_source_value,
   measurement_source_concept_id,
   valueuom as unit_source_value,
   value_source_value
FROM
(SELECT 
 labevents.row_id as measurement_id, 
 labevents.subject_id as person_id,
 main_concept.concept_id,
 CAST( labevents.charttime as DATE ) as measurement_date,
 CAST( labevents.charttime as TIME ) as measurement_time,
 CASE
      WHEN labevents.hadm_id IS NOT NULL = TRUE THEN 45877824  -- It mean that it was measured in the ICU
      ELSE 45461226 -- could be anything else
 END as measurement_type_concept_id,
 CASE
   
	WHEN labevents.value ILIKE '%:%' THEN 000000 -- ???? 
	WHEN labevents.value ILIKE '%/%' THEN 000000 -- ???? 
	WHEN labevents.value ILIKE '%-%' THEN 000000 -- Range 
	WHEN labevents.value ILIKE '%<=%' THEN 4171754 -- SNOMED Meas Value Operator (<=) 
	WHEN labevents.value ILIKE '%<%' or LOWER(labevents.value) ILIKE '%less than%' THEN 4171756 -- SNOMED Meas Value Operator (<) 
	WHEN labevents.value ILIKE '%>=%' THEN 4171755 -- SNOMED Meas Value Operator (>=) 
	WHEN labevents.value ILIKE '%>%' or LOWER(labevents.value) ILIKE '%greater than%' THEN 4172704 -- SNOMED Meas Value Operator (>) 
	ELSE 0 
   END as operater_concept_id,
 valuenum as value_as_number,
 CASE 
	WHEN LOWER(labevents.value) = 'neg' or LOWER(labevents.value) = 'negative' THEN 9189 -- SNOMED Measurement value: Negative 
	WHEN LOWER(labevents.value) = 'pos' or LOWER(labevents.value) = 'positive' THEN 9191 -- SNOMED Measurement value: Negative 
	WHEN LOWER(labevents.value) = 'borderline' THEN 4162852 -- SNOMED Measurement value: boderline 
	WHEN LOWER(labevents.value) = 'low' THEN 45881258 
	WHEN LOWER(labevents.value) = 'high' THEN 45880619
	WHEN LOWER(labevents.value) = 'normal' THEN 45884153
	WHEN LOWER(labevents.value) = 'intubated' THEN 45884415
	WHEN LOWER(labevents.value) = 'not intubated' THEN 4134640
	ELSE '0'
   END as value_as_concept_id,
   labevents.hadm_id as visit_occurence_id, 
   d_labitems.label as measurement_source_value,
   labevents.itemid as measurement_source_concept_id,
   labevents.valueuom as valueuom,
   CASE
	WHEN ( length( labevents.value ) > 45 ) THEN CONCAT( LEFT ( labevents.value, 45 ), '...')
	ELSE labevents.value  --
   END as value_source_value,
   d_labitems.loinc_code as loinc_code


FROM
  mimiciii.labevents
INNER JOIN mimiciii.d_labitems ON d_labitems.itemid = labevents.itemid
LEFT JOIN ohdsi.concept as main_concept ON main_concept.concept_code = d_labitems.loinc_code
WHERE is_number(CAST(main_concept.concept_id AS TEXT)) = TRUE
	and subject_id > 82000 -- for test purpose (limiting the number of subjects)
--LIMIT 1000
) as temp_table
LEFT JOIN ohdsi.concept as unit_concept on LOWER( unit_concept.concept_code) = LOWER(temp_table.valueuom)
---WHERE patients.subject_id = labevents.subject_id and patients.subject_id > 82000
