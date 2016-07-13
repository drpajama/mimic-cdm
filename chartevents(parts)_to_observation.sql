/*

Features selection - features expected to be consistently precise/accurate? 

# done: gcs. afib on tele. arterial pressure ('arterial BP' or 'arterial pressure

   PEEP, measured.
   PEEP, setting (VENT) 
   lead reading: sinus tachy, afib

# issues: minus arterial pressure? isolation? crackles? (there is snomed code but hard to specify the location.
     could it be an objective measure/feature as it is highly dependent on performer/facility settings?
  Tidal volume setting vs spontaenous tidal volume without vent vs tidal volume observed on ventilation     
  some ICU parameters are abscent in CODE: e.g. Mean airway pressure (just 'airway pressure' is present)
temperature locations? 
  
# Measurement Targets of Interest: 

(1) Vital Signs, including saturation 
(2) Heart Rhythm Reading (Not waveform) - e.g. afib, normal sinus 
(3) Precautions
(4) Weight, height 
(5) Vent setting (set) and vent monitoring values : set fio2 
(6) ICU-specific cardiac measurement: CVP, Arterial BP, 
(7) Level of conscious? 
(8) Physical: Bowel sounds, lung sounds (LLL lung sounds, LUL lung sounds) 
(9) Stool guiac positive and negative
(10) Pain
(11) Code???? (DNR is there but..) 

# By System

(1) Neuro: GCS. Conscious? On sededation? SOFA-Neuro 
(2) Cardio: BP (see how there are dealing with BP here!), Central line. Pressor
(3) Pulmo: Vent parameters (Peak and plateau pressure. PEEP. Tidal volume. FiO2. Sat and ABG)
(4) Infectious: On ABx? Fever. WBC.... 
(5) Nephro: Urine output (not here). Input (not here) 
(6) GI: Feeding, Feeding tube.  
(7) 


# Not converted at this moment

* Alarms
* Code status change
* Health care proxy-related charted events
* Declaration without values e.g.  'Skin care'
* Sputum color 
* Side rails 
* Support sytems. 
* Overlap with labevents: e.g. WBC count. LFT
* has health care proxy? 
* oral cavity visualization
* 'Circulation Adequte?'
* 'suctioned - moderate'
* Lung sounds location

# Concept not found in OHDSI concept
1. Precautions
2. Full code
3. Lung sounds location
4. Continuous positive airway pressure (CPAP) + PS? should I do both? issues of settings - setting should be able to overlap?
5. 3 different types of tidal volumes

??
* Vent type: Drager? 

*/


CREATE OR REPLACE FUNCTION is_number(prm_str text) RETURNS BOOLEAN AS $$
DECLARE
  v_return BOOLEAN;
BEGIN
  IF regexp_matches(prm_str,E'^-*[[:digit:]]+\.?[[:digit:]]+$') is not null 
  THEN
     v_return = TRUE;
  ELSE
    IF prm_str ='0' OR prm_str ='1' OR prm_str ='2' OR prm_str ='3' OR prm_str ='4' OR prm_str ='5'
      OR prm_str ='6' OR prm_str ='7' OR prm_str ='8' OR prm_str ='9'
		THEN v_return = TRUE;
    ELSE v_return = FALSE;
    END IF;
  END IF;
  RETURN v_return;     
END
$$ LANGUAGE 'plpgsql';



-- ChartEvents to Observation


-- ChartEvents to Measurement

truncate table ohdsi.measurement;

INSERT INTO ohdsi.measurement (measurement_id, person_id, measurement_concept_id, measurement_date, measurement_time, measurement_type_concept_id, 
	operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, provider_id, visit_occurrence_id, measurement_source_value, measurement_source_concept_id, 
	unit_source_value, value_source_value)

SELECT 
	0 as measurement_id, --
	subject_id as person_id,--
	temp.observation_concept_id as measurement_concept_id,--
	temp.date as measurement_date,--
	temp.time as measurement_time,--
	CASE
		WHEN is_number(CAST(temp.icustay_id as TEXT)) = FALSE THEN 0
		ELSE 45877824 -- ICU
	END as measurement_type_concept_id,--
	0 as operator_concept_id,--
	temp.value_number as value_as_number,--
	temp.value_concept_id,--
	temp.unit_concept_id,--
	0 as provider_id,--
	CASE
		WHEN is_number(CAST(temp.icustay_id as TEXT)) = FALSE THEN hadm_id
		ELSE temp.icustay_id+1000000 
	END as visit_occurrence_id,--
	temp.label as measurement_source_value,--
	temp.itemid as measurement_source_concept_id,
	temp.value1uom as unit_source_value,
	CONCAT( temp.value1, ' ', temp.value2, '(', value1uom , ')') as value_source_value
 FROM 
 (SELECT 
  CASE 
	-- Note: Valid Observation Concepts are not enforced to be from any domain.
	-- They still should be Standard Concepts, and they typically belong to the 
	-- “Observation” or sometimes “Measurement” domain.
	--WHEN is_number (CAST( observation_concept_translator.target_concept_id as varchar(20))) = TRUE 
	--	THEN observation_concept_translator.target_concept_id -- Uses translator table

	-- Basic Measurements
	WHEN LOWER(label) = 'admit wt' THEN 4268280 -- SNOMED Observation for 'baseline weight'
	WHEN LOWER(label) = 'admit ht' THEN 4177340 -- SNOMED Observation for 'body height measure'
	WHEN LOWER(label) = 'daily weight' THEN 40786050 -- (LOINC/Measurement for 'Weight')
	WHEN LOWER(label) ILIKE 'present weight%' THEN 40786050 -- (LOINC/Measurement for 'Weight')
	WHEN LOWER(label) ILIKE 'weight kg' THEN 40786050 -- (LOINC/Measurement for 'Weight')
	WHEN LOWER(label) = 'weight change' THEN 4268831 -- (SNOMED/Measurement for 'Weight change finding')
	--WHEN LOWER(label) = 'birthweight' THEN 

	-- Clinical Scorings
	WHEN LOWER(label) ILIKE '%overall sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(label) ILIKE '%cardiovascular sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(label) ILIKE '%respiratory sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(label) ILIKE '%hematologic sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(label) ILIKE '%renal sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(label) ILIKE '%neurologic sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(label) ILIKE '%hepatic sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(label) ILIKE 'RSBI%' THEN -1 -- THere is no concept code for 'rapid shallow breathing index'
	WHEN LOWER(label) ILIKE 'calculated saps%' THEN 45434748

	-- Clinical Assessment (Should be moved to observation)
	WHEN LOWER(label) = 'orientation' THEN 4183166 -- SNOMED Observation for 'Orientation' 
	WHEN LOWER(label) = 'pupil size r/l' THEN 4062823 -- SNOMED Condition for 'O/E - pupil size'
	
	-- GCS
	WHEN LOWER(label) = 'gcs total' THEN 40623633 -- Measurement: GCS

	-- Temperature
	WHEN LOWER(label) ilike 'temperature c%' THEN 40786332 -- LOINC/Temperature, F is calculated so no need for migration. the site is unspecified 
	WHEN LOWER(label) = 'temp. site' AND LOWER(value1) = 'blood' THEN 3007416 -- LOINC/Measurement: 'Body temperature - Intravascular'
	WHEN LOWER(label) = 'temp. site' AND LOWER(value1) = 'oral' THEN 3006322 
	WHEN LOWER(label) = 'temp. site' AND LOWER(value1) = 'axillary' THEN 3025085 
	WHEN LOWER(label) = 'temp. site' AND LOWER(value1) = 'rectal' THEN 3022060 
	WHEN LOWER(label) = 'inspired gas temperature' THEN 4353948
	
	-- BP
	WHEN LOWER(label) IN ( 'arterial bp mean' , 'radial map') THEN 4108290
	WHEN LOWER(label) = 'arterial bp' THEN 4302410
	WHEN LOWER(label) = 'nbp' THEN 4326744
	WHEN LOWER(label) = 'nbp mean' THEN 4108289

	-- Heart Rate
	WHEN LOWER(label) = 'heart rate' THEN 3027018 -- LOINC Code for HR 

	-- Respiratory Rate
	WHEN LOWER(label) = 'resp rate' or LOWER(label) = 'respiratory rate' or LOWER(label) = 'resp rate (total)'  THEN 3024171 -- LOINC Code for Resp Rate
	WHEN LOWER(label) = 'resp rate (spont)' OR LOWER(label) = 'spont resp rate' THEN 4154772 -- SNOMED code for 'Rate of spontaneous respiratorion'

	-- Oxygen saturation
	WHEN LOWER(label) = 'spo2' THEN 40762499 
	WHEN LOWER(label) = 'cao2' THEN 40772930 -- LOINC/Measurement - Oxygen Content
	
	-- Cardic monitoring

	WHEN LOWER(label) = 'cardiac index' THEN 4208254 --- SNOMED Code for Cardiac Index (Observation) 
	WHEN LOWER(label) ILIKE 'c.o.%' THEN 3005555 --- LOINC Code for LV Cardiac Output (Measurement) 

	WHEN LOWER(label) = 'heart rhythm' THEN 40630178 --- SNOMED Code for Cardiac Rhythm [Observable Entity]
	WHEN LOWER(label) = 'respiratory rate' THEN  86290005 --- 
	WHEN LOWER(label) = 'precaution' AND LOWER(value1) = 'contact' THEN 000000 --'contact precaution'
	WHEN LOWER(label) = 'arterial bp' or LOWER(label) = 'arterial bp mean' THEN 4108290
	WHEN LOWER(label) = 'temperature f' THEN 4022230

	WHEN LOWER(label) = 'pap mean' THEN 4353611 -- SNOMED Observation for Pulmonary artery pressure
	WHEN LOWER(label) = 'pap s/d' THEN 4353855 -- SNOMED Observation for Pulmonary artery systolic pressure
	WHEN LOWER(label) = 'swan svo2' THEN 0
        WHEN LOWER(label) = 'svi' THEN -1
        WHEN LOWER(label) = 'svri' THEN -1
        WHEN LOWER(label) = 'stroke volume' THEN -1

        WHEN LOWER(label) = 'swan svo2' THEN 4096100 -- SNOMED Measurement for 'Mixed venous oxygen saturation measurement'

        -- IABP-related

        WHEN LOWER(label) = 'IABP setting' THEN -1
        WHEN LOWER(label) = 'BAEDP' THEN 0 -- Balloon Aortic End Diastolic Pressure
        
	-- Vent setting

	-- VENT / PEEP-related
	WHEN LOWER(label) = 'peep set' or LOWER(label) = 'peep' THEN 4216746 -- SNOMED Clinical observation for 'Positive end expiratory pressure setting'
	WHEN LOWER(label) = 'auto-peep level'  THEN -1 -- Concept not available 
	WHEN LOWER(label) ILIKE 'total peep%' or LOWER(label) = 'measured peep'THEN 4353713 -- SNOMED Clinical observation for 'Positive end expiratory pressure'

	-- VENT / Tidal volume
	WHEN LOWER(label) IN ('spont. tidal volume', 'tidal volume (spont)', 'spont tidal volumes'
	 ,'spon. vt (l) (mech.)') THEN 4108448 -- SNOMED Clinical observation for 'spontaneous tidal volume'
	WHEN LOWER(label) = 'tidal volume (obser)' THEN 4108137 -- SNOMED Clinical observation for 'ventilator delivered tidal volume'
	WHEN LOWER(label) = 'tidal volume' or LOWER(label) = 'tidal volume (set)' THEN 4220163 -- SNOMED Clinical observation for 'tidal volume setting' 

	-- VENT / Respiratory rate set
	WHEN LOWER(label) = 'respiratory rate set' THEN 4108138 -- SNOMED Observation 'Ventilator rate' 

	-- VENT / FiO2
	WHEN LOWER(label) IN ('fio2', 'fio2 [meas]', 'fio2 set', 'fio2 (analyzed)', 'vision fio2') THEN 4353936 
	WHEN LOWER(label) ILIKE 'o2 flow%' THEN 3005629

	-- VENT / Other vent monitoring parameters
	WHEN LOWER(label) IN ('mean airway pressure') THEN 44782824 
	WHEN LOWER(label) IN ('peak insp. pressure') THEN 4139633
	WHEN LOWER(label) IN ('plateau pressure') THEN 44782825
	WHEN LOWER(label) ILIKE 'pressure support' THEN 3000461
	WHEN LOWER(label) IN ('compliance (40-60ml)') THEN 4090322 -- 'Static lung compliance'
	WHEN LOWER(label) IN ('o2 delivery device') THEN 4036936
	WHEN LOWER(label) IN ('i:e ratio') THEN 4084278

	-- Other resp
	WHEN LOWER(label) IN ('hourly pfr') THEN 4197461
	
	-- Feeding
	WHEN LOWER(label) IN ('diet type') THEN 4043372 --- "Feeding"/Observation/SNOMED

-- 'lvad flow lpm''
	 
	-- Other circulation-related monitoring
	WHEN LOWER(label) = 'cvp' THEN 4323687

	-- Neuro parameters
	WHEN LOWER(Label) = 'icp' THEN 4353953
	WHEN LOWER(label) = 'ccp' THEN 4353710 -- Cerebral perfusion pressure

	-- Other
	WHEN LOWER(label) = 'bladder pressure' THEN 4090339
	WHEN LOWER(label) = 'abi (r)' THEN 44805247
	WHEN LOWER(label) = 'abi (l)' THEN 44805248
	
	ELSE 0
	
  END as observation_concept_id,
  CASE
	WHEN LOWER(label) = 'pupil size r/l' THEN CAST ( substring(value1 FROM '[0-9]+') as INTEGER ) -- 2mm --> 2
	ELSE chartevents.value1num
  END as value_number,
  CASE 
	WHEN is_number(value1) != TRUE THEN chartevents.value1
	WHEN LOWER(label) = 'iabp setting' THEN chartevents.value1
	WHEN LOWER(label) = 'pap s/d' THEN CONCAT( value1, '/', value2) -- Pulmonary artery systolic/diastolic pressure
	ELSE NULL
  END as value_str, 
  chartevents.icustay_id, 
  CASE
	-- Clinical assessment
	WHEN LOWER(value1) = 'pinpoint' THEN 4061876 -- SNOMED Condition: 'O/E - pinpoint pupils'
	WHEN LOWER(value1) = 'fully dilated' THEN 4290615 -- SNOMED Clinical finding: 'Dilatated pupil'
	-- O2 Delivery Methods
	WHEN LOWER(value1) = 'none' THEN 45881798 -- LOINC Meas Value: "Room Air" 
	WHEN LOWER(value1) = 'face tent' THEN 4138487 -- SNOMED Device: "Face tent oxygen delivery device"
	WHEN LOWER(Value1) = 't-piece' THEN 4188570 -- SNOMED Device: "T-piece without bag"
	WHEN LOWER(value1) = 'nasal cannula' THEN 4224038 -- SNOMED Device: "oxygen Nasal cannula"
	WHEN LOWER(value1) = 'non-rebreather' THEN 4145528
	WHEN LOWER(value1) = 'aerosol-cool' THEN 4145694 -- SNOMED Device: "aerosol oxygen mask"
	WHEN LOWER(value1) = 'ventilator' THEN 40493026 -- SNOMED Device: "mechanical ventilator"
	WHEN LOWER(value1) = 'trach mask' THEN 45760219
	WHEN LOWER(value1) = 'venti mask' THEN 4322904 -- SNOMED Device: "venturi mask"
	WHEN LOWER(value1) = 'bipap mask' THEN 45767334 -- SNOMED Device: "Bipap face mask, single use"
	WHEN LOWER(value1) = 'hi flow neb' THEN 4139525 -- SNOMED Device: "high flow oxygen nasal cannula"
	--WHEN LOWER(value1) = ''

	-- Cardiac monitoring
	WHEN LOWER(value1) = 'sinus tachy' THEN 4007310
	WHEN LOWER(value1) = 'atrial fib' THEN 313217 
	WHEN LOWER(value1) = 'sinus brady' THEN 4171683 -- SNOMED Condition for Sinus bradycardia
	WHEN LOWER(value1) = 'normal sinus' THEN 4276669 -- SNOMED Condition for Normal sinus 
	WHEN LOWER(value1) = '1st deg av block' THEN 314379 -- SNOMED Condition for 'First degree atrioventricular block'
	WHEN LOWER(value1) = '2nd deg av block' THEN 318448 -- SNOMED Condition for 'second degree atrioventricular block'
	WHEN LOWER(value1) = '2nd avb/mobitz i' THEN 4205137 
	WHEN LOWER(value1) = '2nd avb/mobitz ii' THEN 313780 
	WHEN LOWER(value1) = 'comp heart block' THEN 40288216
	WHEN LOWER(value1) = 'av paced' THEN 4088998 -- SNOMED Measurement for 'AV sequential pacing pattern'
	WHEN LOWER(value1) = 'a paced' THEN 4089488 -- SNOMED Measurement for 'Atrial pacing pattern'
	WHEN LOWER(value1) = 'v paced' THEN 4092038 -- SNOMED Measurement for 'ventricular pacing pattern'
	WHEN LOWER(value1) = 'atrial flutter' THEN 314665
	WHEN LOWER(value1) = 'junctional' THEN 4038688 -- SNOMED Condition for 'junctional rhythm'
	WHEN LOWER(value1) = 'multfocalatrtach' THEN 0
	WHEN LOWER(value1) = 'parox atrial tach' THEN 0
	WHEN LOWER(value1) = 'supravent tachy' THEN 4275423
	WHEN LOWER(value1) = 'vent. tachy' THEN 4275423
	WHEN LOWER(value1) = 'asystole' THEN 4216773
	WHEN LOWER(stopped) = 'd/c''d' THEN 4132627 -- SNOMED Observation for 'Discontinued' (Mostly for mechanical vent)
	WHEN LOWER(value1) = 'tube feeding' THEN 4222605 -- SNOMED Observation / Tube feeding diet
	WHEN LOWER(value1) = 'diabetic' THEN 4052041 -- SNOMED Observation / Diabetic diet
	WHEN LOWER(value1) = 'full liquid' THEN 4033731 -- SNOMED Obsevation / Liquid diet
	WHEN LOWER(value1) = 'clear liquid' THEN 4033731 -- SNOMED Obsevation / Liquid diet (not diferrentiated from full liquid)
	WHEN LOWER(value1) = 'npo' THEN 4033731 -- SNOMED Observation / 'nothing by mouth status'
	WHEN LOWER(value1) = 'tpn' THEN 45881254 -- LOINC Meas Value / 'TPN' 
	WHEN LOWER(value1) = 'renal' THEN 0 -- renal diet
	WHEN LOWER(value1) ILIKE '%low cholest' THEN 4215995 -- SNOMED Clinica Obs: Low cholesterol diet
	WHEN LOWER(value1) = 'soft solid' THEN 4301609 -- SNOMED Clinica Obs: Soft diet
	ELSE NULL
  END as value_concept_id,
 
  --value_concept_translator.target_concept_id as value_concept_id,
  CAST ( charttime AS DATE) as date, 
  CAST ( chartevents.charttime AS TIME) as time,
  --chartevents.value1num as source_value, 

  CASE 
	--WHEN is_number (CAST( unit_concept_translator.target_concept_id as varchar(20))) = TRUE 
	--	THEN unit_concept_translator.target_concept_id 
	WHEN LOWER(value1uom) = 'mmhg' THEN 8876
	WHEN LOWER(value1uom) = 'deg. f' THEN 9289
	WHEN LOWER(value1uom) = 'deg. c' THEN 8653
	WHEN LOWER(value1uom) = 'l/min' THEN 8698
	WHEN LOWER(value1uom) = 'kg' THEN 9529
	WHEN LOWER(value1uom) = 'bpm' THEN 8541 -- UCUM per minute 
	WHEN LOWER(value1uom) = '%' THEN 8554
	WHEN LOWER(value1uom) = 'cmh2o' THEN 44777590
	WHEN LOWER(value1uom) = 'ml/b' THEN 8587 -- UCUM unit for 'milliliter' (there is no unit avilable for ml per breath but it doesnt really matter...)
	WHEN LOWER(value1uom) = 'torr' THEN 4136788
	WHEN LOWER(label) = 'pupil size r/l' THEN 8588 -- Millimeter 
	ELSE 0 
  END as unit_concept_id,
 
  --chartevents.value1uom as unit_source_value, 
  
 -- chartevents.elemid, 
  
  chartevents.value1, 
  chartevents.value2, 
 /* chartevents.value2num,*/ 
  chartevents.value1uom, 
 
 /* chartevents.stopped, */
  d_chartitems.label, 
  d_chartitems.category, 
  d_chartitems.description,
  chartevents.resultstatus,
  d_chartitems.itemid,
  chartevents.subject_id,
  icustay_detail.hadm_id
 -- value_concept_translator.target_concept_id as value_translated_id
FROM 
  mimic2v26.chartevents 
 -- mimic2v26.d_chartitems
  INNER JOIN mimic2v26.d_chartitems on d_chartitems.itemid = chartevents.itemid 
  LEFT JOIN mimic2v26.icustay_detail on chartevents.subject_id = icustay_detail.subject_id ) as temp
  
WHERE temp.observation_concept_id != 0 
 
/*WHERE 
 
  COALESCE(d_chartitems.category, '') NOT ILIKE '%ABG%' AND  
  COALESCE(d_chartitems.category, '') NOT ILIKE '%VBG%' AND 
  COALESCE(d_chartitems.category, '') != 'Chemistry' AND COALESCE(d_chartitems.category, '') != 'Coags' AND
  COALESCE(d_chartitems.category, '') != 'Hematology' AND COALESCE(d_chartitems.category, '') != 'Enzymes' AND 
  COALESCE(d_chartitems.category, '') NOT ILIKE '%Gases%' AND 
  COALESCE(d_chartitems.category, '') != 'Heme/Coag' AND COALESCE(LOWER(d_chartitems.category), '') != 'drug level' AND COALESCE(LOWER(d_chartitems.category), '') != 'csf' AND 
  COALESCE(d_chartitems.category, '') != 'Urine' AND
  LOWER(d_chartitems.label) NOT IN ( 'skin care', 'turn', 'pressurereducedevice', 'therapeutic bed', 'calprevflg' , 'inv#3 dsg change', 'risk for falls', 'bath', 'assistance device', 'back care', 'activity tolerance', 
  'pressure sore odor#1', 'reason for restraint', 'tach care', 'side rails', 'trach size', 'tracheostomy cuff' ) AND
  LOWER(d_chartitems.label) NOT ILIKE '%alarm%' AND 
  LOWER(d_chartitems.label) NOT ILIKE '%#1%' AND 
  LOWER(d_chartitems.label) NOT ILIKE '%#2%' AND LOWER(d_chartitems.label) NOT ILIKE '%#3%' AND
  LOWER(d_chartitems.label) NOT ILIKE '%systolic unloading%' and
  LOWER(d_chartitems.label) NOT ILIKE '%eye care%' and
  LOWER(d_chartitems.label) NOT ILIKE '%behavior%' and 
  LOWER(d_chartitems.label) NOT ILIKE '%INV%'and 
  LOWER(d_chartitems.label) NOT ILIKE '%antiembdevice%' and 
  LOWER(d_chartitems.label) NOT ILIKE '%behavior%' and 
  LOWER(d_chartitems.label) NOT ILIKE '%trach%'and 
  LOWER(d_chartitems.label) NOT ILIKE '%activity%'
  and 
  LOWER(d_chartitems.label) NOT ILIKE '%precautions%' and 
  LOWER(d_chartitems.label) NOT ILIKE '%code status%'
  and 
  LOWER(d_chartitems.label) NOT ILIKE '%lung sounds%'
  
  and LOWER(d_chartitems.label) NOT ILIKE '%alarm%'  
  
  and LOWER(d_chartitems.label) NOT ILIKE '%dialysis%'  
  
  and LOWER(d_chartitems.label) NOT ILIKE '%impskin%'  
  
  and LOWER(d_chartitems.label) NOT ILIKE '%impaired skin%' 
  and LOWER(d_chartitems.label) NOT ILIKE '%movement%'  
  and LOWER(d_chartitems.label) NOT ILIKE '%braden%'   
  and LOWER(d_chartitems.label) NOT ILIKE '%iv site appear%'  
  and LOWER(d_chartitems.label) NOT ILIKE '%temp/color%'  
  and LOWER(d_chartitems.label) NOT ILIKE '%site/size%'  
  and LOWER(d_chartitems.label) NOT ILIKE '%dialysate%' -- note: dialysis is not covered for now
  
  --and lower(label) ILIKE '%heart rhythm%'*/
  /*
  and lower(d_chartitems.label) NOT IN ('arterial bp mean', 'eye opening', 'temperature c (calc)', 'verbal response',
  'education response', 'posttib. pulses r/l', 'skin temp/condition', 'skin integrity', 'inspired gas temp', 'oral care'
  ,'bowel sounds', 'apnea time interval', 'health care proxy', 'oral cavity', 'removed x 5 mins'
  , 'restraint location', 'restraint type', 'support systems', 'riker-sas scale', 'stool management'
  , 'range of motion', 'current goal', 'skin color', 'pain present', 'cuff leak', 'rsbi (<100)', 'position'
  , 'hob', 'respiratory pattern' ,'religion', 'bsa', 'spontaneous movement', 'follows commands', 'ectopy frequency'
  , 'airway size', 'daily wake up' ,'cough reflex', 'plateau-off', 'speech', 'education readiness', 'ventilator mode',
  'gu catheter size', 'airway type', 'gi prophylaxis', 'sensitivity-vent','urine source', 'pain level (rest)', 'cough effort', 've high'
  , 'bsa - metric', 'waveform-vent', 'less restrict meas.', 'tank b psi.', 'restraints evaluated', 'previous weightf', 'tank a psi.'
  ,'pacemaker type', 'education method', 'pain type', 'ett mark/location', 'education learner', 'rue temp/color', 'ectopy type'
  , 'bsa - english', 'communication', 'pacer wires atrial', 'ventilator no.', 'flow-by sensitivity',
  'low exhaled min vol', 'flow-by (lpm)', 'ventilator type', 'abdominal assessment', 'neuro symptoms', 'education handout',
  'readmission', 'pain assess method', 'pacer wire condition','circulation/skinint', 'pain location', 'high resp. rate',
   'minute volume(obser)' , 'neuro drain lev/loc', 'neuro drain type', 'neuro drain status', 'neuro drain drainge',
   'radiologic study', 'high exhaled min vol', 'augmented diastole', 'assisted systole', 'resopnds to stimuli',
   'cervical collar type', 'pupil response r/l', 'family communication', 'suctioned', 'position change', 'sputum source/amt'
   , 'pain level' , 'education barrier', 'pa line cm mark', 'incentive spirometry', 'parameters checked'
   , 'martial status', 'previous weight', 'motor response', 'responds to stimuli', 'level of conscious'
   , 'pain management', 'high min. vol' , 'significant events', 'nursing consultation', 'return pressure mmhg',
   'marital status', 'access mmgh', 'art lumen volume', '% inspir. time', 'abi ankle bp r/l', 'abi brachial bp r/l')
  --and LOWER(d_chartitems.label) ILIKE '%sofa%'*/
  
  --and is_number ( value_concept_id ) = FALSE
 --) as temp WHERE temp.observation_concept_id!=0 LIMIT 200


-- Conversion Target Necessary / Included: 
-- Conversion Target Necessary but with issues:
-- Conversion Target Not Included


-- D_ITEMS is sourced from two distinct ICU databases. The main consequence is that there are duplicate ITEMID for each concept. For example, heart rate is captured both as an ITEMID of 212 (CareVue) and as an ITEMID of 220045 (Metavision). As a result, it is necessary to search for multiple ITEMID to capture a single concept across the entire database. This can be tedious, and it is an active project to coalesce these ITEMID - one which welcomes any and all help provided by the community!


 