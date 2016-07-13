
-- Populate Care Site

/* MIMIC3 data was collected in Beth Israel Deaconess Hospital and these
Table can be populated manually.*/

-- Type of ICU includes: 
-- Please See: http://www.bidmc.org/Patient-and-Visitor-Information/Adult-Intensive-Care/About-Adult-IntensiveCareatBIDMC.aspx
-- (1) 'CCU'  : Cardiac/Coronary Care Unit
-- (2) 'MICU' : Medical ICU
-- (3) 'SICU' : Surgical ICU
-- (4) 'FICU' : Called Finard ICU for some historical reason. FICU/SICU combined unit, located on the West Campus (All other units are on the East Campus)
-- (5) 'CSRU' : Cardiac Surgery Recovery Unit
-- (6) 'NICU' : NeuroICU

/* Related Concept Codes
- Adult Critical Care Unit (LOINC/45877824) -> Will use for ICUs without proper concept codes
- Adult Medical Critical Care Unit (LOINC/45881476)
- Adult Coronary Critical Care Unit (LOINC/45885090)
- Adult Cardiothoracic Critical Care Unit (LOINC Meas Value/45881475)
- Adult Coronary Critical Care Unit (LOINC Meas Value/45885090)
- Neuro ICU (LOINC/45881477) 
- Surgical ICU (LOINC/45877825) 
- Adult Trauma Critical Care Unit (LOINC Meas Value/45885091)
- Postoperative Anethesia Care Unit (LOINC/45880582)
- Special Care Unit (SNOMED/4166938)

-- 'CCU' --> Coronary Unit, 'CTIC' --> Cardiothoracic ICU
-- '' 
-- UNKNOWN --> 0
-- T_CTICU --> 
-- Regular Ward --> 
-- PACU -->
-- PCU -->
-- FICU --> ICU
-- NICU --> Neurologic ICU
-- NSICU --> Neurologic ICU (Could bd Controversial!)
-- CSRU --> Cardiothoracic ICU (Looke like = CTICU?)

*/
-- The website above mentioned that BIDMC has CVISU (not CCU) and Trauamtic ICU but not found in the MIMIC data
-- Note that the table has first_careunit and last_careunit column, which might have the same icu_stay id. 
-- For now, the icu type will be just 'ICU' if first_careunit != last_careunit. 
-- We will use icustay_id as visit_occurance id. 


SELECT * from mimic2v26.icustay_detail
WHERE random () < 0.1;


-- Care Site (Done manually!)

-- Renew the table for care_site
truncate table ohdsi.care_site;

INSERT INTO ohdsi.care_site(care_site_id, care_site_name, place_of_service_concept_id, care_site_source_value, place_of_service_source_value)
VALUES 
	(1, 'Adult Medical ICU', 45881476, '69', 'MICU'),
	(2, 'Adult Coronary Care Unit', 45885090, '1', 'CCU'),
	(3, 'Adult Surgical ICU', 45877825, '6', 'SICU'),
	(4, 'Cardiothoracic CCU', 45881475, '2', 'CTIC'),
	-- Finard ICU is a Med+Sug ICU in the west campus of BIDMC. Will be assigned to simply 'ICU'
	(5, 'Finard ICU (Concept_id is simply ICU)', 45877824, '53', 'FICU'),
	(6, 'Neurologic ICU', 45881477, '75', 'NICU'),
	(7, 'Surgical ICU', 45877825, '6', 'SICU'),
	-- Using the concept id for CTICU
	(8, 'Cardiac Surgery Recovery Unit', 45881475, '54', 'CSRU'),
	(9, 'Postoperative Anethesia Care Unit', 45880582, '46', 'PACU'),
	(10, 'Adult Trauma Critical Care Unit', 45885091, '7', 'T_CTICU'),
	-- The is no concept id for NeuroSurgical ICU, so we're using the id for NICU
	(11, 'Neurosurgical ICU', 45881477, '56', 'NSICU'),
	-- There is no concept id for PCI. The id for 'special care unit' is used.
	(12, 'Progressive Care Unit (PCU)', 4166938, '48', 'PCU'),
	(13, 'Regular Ward', 4024317, '8', 'Regular Ward');
	
-- ICU Stay to Visit Occurence 
-- visit occurence can be icu visit, but it might be simply ward visit.
-- we will add 100,000 to the icustay_id, so it could 'overlap' with 

truncate table ohdsi.visit_occurrence;


INSERT INTO ohdsi.visit_occurrence (visit_occurrence_id, person_id, visit_concept_id, visit_start_date, visit_start_time, visit_end_date, visit_end_time
	, visit_type_concept_id, provider_id, care_site_id, visit_source_value, visit_source_concept_id)
SELECT icustay_id + 100000 as visit_occurrence_id, subject_id as person_id, 
	9201 as visit_concept_id, -- visit ID for 'inpatient visit' (there is no visit domain for ICU stay)
	CAST(icustay_intime as DATE) as visit_start_date,
	CAST(icustay_intime as TIME) as visit_start_time,
	CAST(icustay_outtime as DATE) as visit_end_date,
	CAST(icustay_outtime as TIME) as visit_end_time,
	0 as visit_type_concept_id,
	NULL as provider_id,
	care_site.care_site_id as care_site_id,
	NULL as visit_source_value,
	NULL as visit_source_concept_id
 FROM mimic2v26.icustay_detail
LEFT JOIN ohdsi.care_site ON care_site.place_of_service_source_value = icustay_first_service

/*INSERT INTO visit_occurrence (visit_occurrence_id, person_id, visit_concept_id, visit_start_date, visit_start_time, visit_end_date, visit_end_time, visit_type_concept_id, visit_source_concept_id)
SELECT icustay_id, subject_id, 9203, begintime, pg_catalog.time(begintime), endtime, pg_catalog.time(endtime), 0, 0
FROM mimic2v26.icustay_days;*/






