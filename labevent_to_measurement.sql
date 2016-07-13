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
   0 as measurement_id, --
   mimic2v26.labevents.subject_id as person_id, --
   CASE 
	WHEN main_concept.concept_id IS NOT NULL = TRUE THEN main_concept.concept_id
	WHEN lower(d_labitems.test_name) = 'bands' THEN 40782560 
	WHEN lower(d_labitems.test_name) = 'hct' THEN 3009542
	WHEN lower(d_labitems.test_name) = 'cd34' THEN 44817307
	WHEN lower(d_labitems.test_name) = 'tacrofk' THEN 4310327
	WHEN lower(d_labitems.test_name) = 'intubated' THEN 4158191
	WHEN lower(d_labitems.test_name) = 'crp' THEN 45888376
	ELSE 0
   END as measurement_concept_id, --
   CAST( labevents.charttime as DATE ) as measurement_date, --
   CAST( labevents.charttime as TIME ) as measurement_time, --
   CASE
      WHEN labevents.hadm_id IS NOT NULL = TRUE THEN 45488053  -- Inpatient care (general inpatient + ICU)
      ELSE 45461226 -- outpatient care
   END as measurement_type_concept_id, -- 
   CASE
   
	WHEN labevents.value ILIKE '%:%' THEN 000000 -- ???? 
	WHEN labevents.value ILIKE '%/%' THEN 000000 -- ???? 
	WHEN labevents.value ILIKE '%-%' THEN 000000 -- Range 
	WHEN labevents.value ILIKE '%<=%' THEN 4171754 -- SNOMED Meas Value Operator (<=) 
	WHEN labevents.value ILIKE '%<%' or LOWER(labevents.value) ILIKE '%less than%' THEN 4171756 -- SNOMED Meas Value Operator (<) 
	WHEN labevents.value ILIKE '%>=%' THEN 4171755 -- SNOMED Meas Value Operator (>=) 
	WHEN labevents.value ILIKE '%>%' or LOWER(labevents.value) ILIKE '%greater than%' THEN 4172704 -- SNOMED Meas Value Operator (>) 
	ELSE 0 
   END as operater_concept_id, --
   CASE
	
	WHEN labevents.value ILIKE '%:%' THEN CAST ( substring(labevents.value FROM '[0-9]+') as FLOAT ) -- ????
	WHEN labevents.value ILIKE '%/%' THEN CAST ( substring(labevents.value FROM '[0-9]+') as FLOAT ) -- ???? 
	WHEN labevents.value ILIKE '%-%' THEN CAST ( substring(labevents.value FROM '[0-9]+') as FLOAT )
	WHEN labevents.value ILIKE '%<%' or LOWER(labevents.value) ILIKE '%less than%' 
		OR labevents.value ILIKE '%>%' or LOWER(labevents.value) ILIKE '%greater than%' 
		OR  LOWER(labevents.value) ILIKE '%-%' 
		THEN CAST ( substring(labevents.value FROM '[0-9]+') as FLOAT )
	WHEN is_number ( labevents.value ) = TRUE THEN CAST ( labevents.value as FLOAT )
	ELSE 0 
   END as value_as_number, -- 
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
   END as value_as_concept_id, --
     CASE 
      --  WHEN unit_concept.concept_id != NULL THEN unit_concept.concept_id
        -- Many units can be found in concept table
	WHEN LOWER(labevents.valueuom) = 'mm hg' OR LOWER(labevents.valueuom) = 'mmhg' 
		OR d_labitems.loinc_code = '19991-9' THEN 8876 -- UCUM Code for millimeter mercury column
	WHEN LOWER(labevents.valueuom) = 'meq/l' THEN 9557
	WHEN labevents.valueuom = '%' THEN 8554
	WHEN LOWER(labevents.valueuom) = 'meq/l' THEN 9557
	WHEN LOWER(labevents.valueuom) = 'mg/dl' THEN 8840
	WHEN LOWER(labevents.valueuom) = 'g/dl' THEN 8713
	WHEN LOWER(labevents.valueuom) = 'mmol/l' THEN 8753
	WHEN LOWER(labevents.valueuom) = 'l/min' THEN 8698
	WHEN d_labitems.loinc_code ='11558-4' OR d_labitems.loinc_code ='2748-2' THEN 8482  -- 11558-4 is LOINC code for pH. 8482 if UCUM code for pH
	WHEN LOWER(labevents.valueuom) = 'iu/l' THEN 8923
	WHEN LOWER(labevents.valueuom) = 'ug/ml' THEN 8859
	WHEN LOWER(labevents.valueuom) = 'ng/ml' THEN 8842
	WHEN LOWER(labevents.valueuom) = 'umol/l' THEN 8749
	WHEN LOWER(labevents.valueuom) = 'iu/ml' THEN 8985
	WHEN LOWER(labevents.valueuom) = 'u/ml' THEN 8763
	WHEN LOWER(labevents.valueuom) = 'ratio' THEN 8523
	WHEN LOWER(labevents.valueuom) = 'ug/dl' THEN 8837
	WHEN LOWER(labevents.valueuom) = 'pg/ml' THEN 8845
	WHEN LOWER(labevents.valueuom) = 'miu/l' THEN 9040
	WHEN LOWER(labevents.valueuom) = 'miu/ml' THEN 9550
	WHEN LOWER(labevents.valueuom) = 'units' THEN 8510
	WHEN LOWER(labevents.valueuom) = 'uiu/l' THEN 44777583
	WHEN LOWER(labevents.valueuom) = 'uiu/ml' THEN 9093
	WHEN LOWER(labevents.valueuom) = 'uu/ml' THEN 9093 -- uIU/mL
	WHEN LOWER(labevents.valueuom) = 'mg/24hr' THEN 8909 
	WHEN LOWER(labevents.valueuom) = 'u/l' THEN 8645 
	WHEN LOWER(labevents.valueuom) = 'ml/min' THEN 8795 
	WHEN LOWER(labevents.valueuom) = '#/cu mm' THEN 8785 -- per cubic millimeter [for WBC or RBC in peritoneal fluid] 
	WHEN LOWER(labevents.valueuom) = '#/uL' THEN 8647
	WHEN LOWER(labevents.valueuom) = 'gpl' THEN 4171221
	WHEN LOWER(labevents.valueuom) = 'score' and d_labitems.loinc_code = '15112-6' THEN 4196800 -- SNOMED code for Leukocyte alkaline phosphatase score (class: procedure) 
	WHEN LOWER(labevents.valueuom) = '/mm3' THEN 8785
	WHEN LOWER(labevents.valueuom) = 'sec' OR LOWER(labevents.valueuom) = 'seconds' THEN 8555
	WHEN LOWER(labevents.valueuom) = 'serum vis' THEN 3010493 -- LOINC code for Viscosity of Serum
	WHEN LOWER(labevents.valueuom) = 'eu/dl' THEN 8829
	WHEN LOWER(labevents.valueuom) = 'mm/hr' THEN 8752
	ELSE 0
   END as unit_concept_id, -- 
   0 as provider_id,  --
   CASE 
	WHEN is_number(CAST(labevents.icustay_id AS TEXT)) = TRUE THEN labevents.icustay_id + 1000000 -- Note that some patients does not have ICU visit ID as the values are for floor/PCU or whatever. In this case, hospital admission id is used instead but 1,000,000 is added to ICU idea to prevent overlap of id
	ELSE labevents.hadm_id
   END as visit_occurence_id, -- 
   CONCAT( d_labitems.test_name, ' / ' , mimic2v26.d_labitems.loinc_code, ' (', 'LOINC', ')') as measurement_source_value, -- 
   0 as measurement_source_concept_id, --
   labevents.valueuom as unit_source_value, -- 
   CASE
	WHEN ( length( labevents.value ) > 45 ) THEN CONCAT( LEFT ( labevents.value, 45 ), '...')
	ELSE labevents.value  --
   END as value_source_value

FROM 
  mimiciii.labevents 
  INNER JOIN mimiciii.d_labitems ON d_labitems.itemid = labevents.itemid 
  LEFT JOIN ohdsi.concept as main_concept ON main_concept.concept_code = mimic2v26.d_labitems.loinc_code
 -- LEFT JOIN ohdsi.concept as unit_concept on LOWER(unit_concept.concept_code) = LOWER(labevents.valueuom)
WHERE is_number(CAST(main_concept.concept_id AS TEXT)) = TRUE 
/*and ( lower(d_labitems.test_name) NOT IN ('misc', 'gr hold', '<crea-p>', '<crea-u>', 'uhold','rbcf', 'other', 'birefri', 'wbcclump', 'envelop', 'epi', 'inh scr'
	, 'ipt', 'cd20', 'cd16', 'cd71', 'fmc-7' ,'young',  'type', 'vent', 'edta hold', 'green hld', 'bc hold', 'ltgrn hld', '')
 AND lower(d_labitems.test_name) NOT IN ('bands', 'hct', 'cd34', 'tacrofk', 'intubated', 'unkcast', 'location', 'number', 'shape', 'rates', 'req o2', 'art', 'ven', 'crp') )   and 
 lower(labevents.value) != 'done'*/
--WHERE mimic2v26.labevents.subject_id = 1371

 


-- Failed to catch: MPL (IgM somewhat unit...). U/g/hb (for 32546-4) 1977-8: SM, LG, MOD (for urine bilirubin) 
