
INSERT INTO ohdsi.measurement (measurement_id, person_id, measurement_concept_id, measurement_date, measurement_time, measurement_type_concept_id, 
	operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, provider_id, visit_occurrence_id, measurement_source_value, measurement_source_concept_id, 
	unit_source_value, value_source_value)

SELECT 
	measurement_id, person_id, measurement_concept_id, measurement_date, measurement_time, measurement_type_concept_id,
	0 as operator_concept_id, value_number, value_concept_id, unit_concept_id, 0 as provider_id, 
	CASE
		WHEN is_number(CAST(temp.icustay_id as TEXT)) = FALSE THEN 00
		ELSE temp.icustay_id+1000000 
	END as visit_occurrence_id, temp.label as measurement_source_value, temp.item_id as measurement_source_concept_id, temp.valueuom as unit_source_value
	, temp.value as value_source_value
FROM (
SELECT (chartevents.row_id + 900000000) as measurement_id, -- labvalue also get into measurement and there is risk of overlapping 
	subject_id as person_id,
	CASE 
	-- Note: Valid Observation Concepts are not enforced to be from any domain.
	-- They still should be Standard Concepts, and they typically belong to the 
	-- “Observation” or sometimes “Measurement” domain.
	--WHEN is_number (CAST( observation_concept_translator.target_concept_id as varchar(20))) = TRUE 
	--	THEN observation_concept_translator.target_concept_id -- Uses translator table

	-- Basic Measurements
	WHEN LOWER(item.label) = 'admit wt' THEN 4268280 -- SNOMED Observation for 'baseline weight'
	WHEN LOWER(item.label) = 'admit ht' THEN 4177340 -- SNOMED Observation for 'body height measure'
	WHEN LOWER(item.label) = 'daily weight' THEN 40786050 -- (LOINC/Measurement for 'Weight')
	WHEN LOWER(item.label) ILIKE 'present weight%' THEN 40786050 -- (LOINC/Measurement for 'Weight')
	WHEN LOWER(item.label) ILIKE 'weight kg' THEN 40786050 -- (LOINC/Measurement for 'Weight')
	WHEN LOWER(item.label) = 'weight change' THEN 4268831 -- (SNOMED/Measurement for 'Weight change finding')
	--WHEN LOWER(label) = 'birthweight' THEN 

	-- Mental Status
	WHEN LOWER(item.label) = 'gcs - verbal response' THEN 3009094
	WHEN LOWER(item.label) = 'gcs - motor response' THEN 3008223
	WHEN LOWER(item.label) = 'gcs - eye opening' THEN 3016335
	
	-- Clinical Scorings
	WHEN LOWER(item.label) ILIKE '%overall sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(item.label) ILIKE '%cardiovascular sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(item.label) ILIKE '%respiratory sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(item.label) ILIKE '%hematologic sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(item.label) ILIKE '%renal sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(item.label) ILIKE '%neurologic sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(item.label) ILIKE '%hepatic sofa%' THEN -1 -- There is no concept code for SOFA
	WHEN LOWER(item.label) ILIKE 'RSBI%' THEN -1 -- THere is no concept code for 'rapid shallow breathing index'
	WHEN LOWER(item.label) ILIKE 'calculated saps%' THEN 45434748

	-- Clinical Assessment (Should be moved to observation)
	WHEN LOWER(item.label) = 'orientation' THEN 4183166 -- SNOMED Observation for 'Orientation' 
	WHEN LOWER(item.label) = 'pupil size r/l' THEN 4062823 -- SNOMED Condition for 'O/E - pupil size'
	
	-- GCS
	WHEN LOWER(item.label) = 'gcs total' THEN 40623633 -- Measurement: GCS

	-- Temperature
	WHEN LOWER(item.label) ilike 'temperature fahrenheit' THEN 9289
	WHEN LOWER(item.label) ilike 'temperature c%' THEN 40786332 -- LOINC/Temperature
	WHEN LOWER(item.label) IN ( 'blood temperature cco (c)' ) THEN 40305166 --- 'core temperature'
	WHEN LOWER(item.label) = 'temp. site' AND LOWER(value) = 'blood' THEN 3007416 -- LOINC/Measurement: 'Body temperature - Intravascular'
	WHEN LOWER(item.label) = 'temp. site' AND LOWER(value) = 'oral' THEN 3006322 
	WHEN LOWER(item.label) = 'temp. site' AND LOWER(value) = 'axillary' THEN 3025085 
	WHEN LOWER(item.label) = 'temp. site' AND LOWER(value) = 'rectal' THEN 3022060 
	WHEN LOWER(item.label) = 'inspired gas temperature' THEN 4353948
	
	-- BP
	WHEN LOWER(item.label) IN ( 'arterial blood pressure mean', 'arterial bp mean' , 'radial map') THEN 4108290 -- 'Invasive mean arterial pressure'
	WHEN LOWER(item.label) = 'arterial blood pressure systolic' THEN 4353843 -- 'Invasive Systolic Pressure'
	WHEN LOWER(item.label) = 'arterial blood pressure diastolic' THEN 4354253 -- 'Invasive Diastolic Pressure'
	WHEN LOWER(item.label) in ('non invasive blood pressure systolic', 'art bp systolic') THEN 4152194 -- 'Systolic blood pressure'
	WHEN LOWER(item.label) in ('non invasive blood pressure diastolic', 'art bp diastolic') THEN 4154790 -- Diastolic blood pressure'
	WHEN LOWER(item.label) in ('non invasive blood pressure mean', 'art bp mean') THEN 4239021 -- 'mean blood pressure'

	-- SWAN-GANTZ
	WHEN LOWER(item.label) = 'pulmonary artery pressure systolic' THEN 4353855
	WHEN LOWER(item.label) = 'pulmonary artery pressure diastolic' THEN 3017188
	WHEN LOWER(item.label) = 'pulmonary artery pressure mean' THEN 3028074

	-- Heart Rate
	WHEN LOWER(item.label) = 'heart rate' THEN 3027018 -- LOINC Code for HR 

	-- Respiratory Rate
	WHEN LOWER(item.label) IN ('resp rate', 'respiratory rate','resp rate (total)', 'respiratory rate (total)')  THEN 3024171 -- LOINC Code for Resp Rate
	WHEN LOWER(item.label) IN ('resp rate (spont)', 'spont resp rate', 'respiratory rate (spontaneous)', 'spont rr') THEN 4154772 -- SNOMED code for 'Rate of spontaneous respiratorion'

	-- Oxygen saturation
	WHEN LOWER(item.abbreviation) = 'spo2' THEN 40762499 
	WHEN LOWER(item.label) = 'cao2' THEN 40772930 -- LOINC/Measurement - Oxygen Content
	
	-- Cardic monitoring

	WHEN LOWER(item.label) IN ( 'cardiac index', 'ci (picco)') THEN 4208254 --- SNOMED Code for Cardiac Index (Observation) 
	WHEN LOWER(item.label) ILIKE 'c.o.%' THEN 3005555 --- LOINC Code for LV Cardiac Output (Measurement) 
	WHEN LOWER(item.label) = 'co (arterial)' THEN 4221102
	WHEN LOWER(item.label) IN ('permanent pacemaker rate') THEN 4215909
	WHEN LOWER(item.label) IN ('temporary pacemaker rate') THEN 4215909 -- not distingushed from permanent pacemaker rate

	WHEN LOWER(item.label) = 'heart rhythm' THEN 40630178 --- SNOMED Code for Cardiac Rhythm [Observable Entity]
	WHEN LOWER(item.label) = 'respiratory rate' THEN  86290005 --- 
	WHEN LOWER(item.label) = 'precaution' AND LOWER(value) = 'contact' THEN 000000 --'contact precaution'
	WHEN LOWER(item.label) = 'arterial bp' or LOWER(label) = 'arterial bp mean' THEN 4108290
	WHEN LOWER(item.label) = 'temperature f' THEN 4022230

	WHEN LOWER(item.label) = 'pap mean' THEN 4353611 -- SNOMED Observation for Pulmonary artery pressure
	WHEN LOWER(item.label) = 'pap s/d' THEN 4353855 -- SNOMED Observation for Pulmonary artery systolic pressure
	WHEN LOWER(item.label) = 'swan svo2' THEN 0
        WHEN LOWER(item.label) ilike ('%svi%') THEN -1
        WHEN LOWER(item.label) IN ( 'svri', 'svri (picco)') THEN -1
        WHEN LOWER(item.label) in ( 'stroke volume', 'sv (arterial)' ) THEN -1
        WHEN LOWER(item.label) in ('svv (arterial)', 'svv (picco)' ) THEN -1 -- Stroke volume variation
	WHEN LOWER(item.label) = 'ef (cco)' THEN 3027172 -- simply 'ejection fraction' 
        WHEN LOWER(item.label) IN ('swan svo2' , 'svo2', 'scvo2 (presep)') THEN 4096100 -- SNOMED Measurement for 'Mixed venous oxygen saturation measurement'

	WHEN LOWER(item.label) IN ('cardiac output (co nicom)', 'co (picco)') THEN 45766800 -- Noninvasive cardiac output monitoring
	WHEN LOWER(item.label) IN ('cardiac index (ci nicom)') THEN 4208254 -- there is no way to specify invasive vs noninvasive

        -- IABP-related

        WHEN LOWER(item.label) = 'IABP setting' THEN -1
        WHEN LOWER(item.label) = 'BAEDP' THEN 0 -- Balloon Aortic End Diastolic Pressure
        
	-- Vent setting

	-- BIPAP
	WHEN LOWER(item.label) in ('bipap epap') THEN 44817050 -- not distingushed from IPAP (but should be recognizable by the number difference)
	WHEN LOWER(item.label) in ('bipap ipap') THEN 44817050 

	-- VENT / PEEP-related
	WHEN LOWER(item.label) = 'peep set' or LOWER(label) = 'peep' THEN 4216746 -- SNOMED Clinical observation for 'Positive end expiratory pressure setting'
	WHEN LOWER(item.label) = 'auto-peep level'  THEN -1 -- Concept not available 
	WHEN LOWER(item.label) ILIKE 'total peep%' or LOWER(label) = 'measured peep'THEN 4353713 -- SNOMED Clinical observation for 'Positive end expiratory pressure'

	-- VENT / Tidal volume
	WHEN LOWER(item.label) IN ('spont. tidal volume', 'tidal volume (spont)', 'spont tidal volumes'
	 ,'spon. vt (l) (mech.)' ,'spont vt') THEN 4108448 -- SNOMED Clinical observation for 'spontaneous tidal volume'
	WHEN LOWER(item.label) = ( 'tidal volume (observed)' ) THEN 4108137 -- SNOMED Clinical observation for 'ventilator delivered tidal volume'
	WHEN LOWER(item.label) = 'tidal volume' or LOWER(label) = 'tidal volume (set)' THEN 4220163 -- SNOMED Clinical observation for 'tidal volume setting' 
	WHEN LOWER(item.label) = 'tidal volume (spontaneous)' THEN 4108448
		
	-- VENT / Respiratory rate set
	WHEN LOWER(item.label) in ( 'respiratory rate set' , 'respiratory rate (set)') THEN 4108138 -- SNOMED Observation 'Ventilator rate' 

	-- VENT / FiO2
	WHEN LOWER(item.label) IN ('fio2', 'fio2 [meas]', 'fio2 set', 'inspired o2 fraction', 'vision fio2') THEN 4353936 
	WHEN LOWER(item.label) ILIKE 'o2 flow%' THEN 3005629

	-- VENT / Other vent monitoring parameters
	WHEN LOWER(item.label) IN ('mean airway pressure', 'paw high') THEN 44782824 
	WHEN LOWER(item.label) IN ('peak insp. pressure') THEN 4139633
	WHEN LOWER(item.label) IN ('plateau pressure') THEN 44782825
	WHEN LOWER(item.label) ILIKE 'pressure support' THEN 3000461
	WHEN LOWER(item.label) IN ('compliance (40-60ml)') THEN 4090322 -- 'Static lung compliance'
	WHEN LOWER(item.label) IN ('o2 delivery device') THEN 4036936
	WHEN LOWER(item.label) IN ('i:e ratio') THEN 4084278
	WHEN LOWER(item.label) IN ('minute volume') THEN 4353621
	WHEN LOWER(item.label) IN ('inspiratory time') THEN 4353947
	WHEN LOWER(item.label) IN ('cuff pressure') THEN 4108458
	WHEN LOWER(item.label) in ('inspired gas temp.') THEN 4353948

	-- Other resp
	WHEN LOWER(item.label) IN ('hourly pfr') THEN 4197461

	-- SWAN-GANTZ
	WHEN LOWER(item.label) IN ('cardiac output (cco)', 'cardiac output (thermodilution)') THEN 4321094 -- 'CO thermodilution'
	WHEN LOWER(item.label) IN ('transpulmonary pressure (insp. hold)', 'pcwp') THEN 4040920 -- 'pulmonary capillary wedge pressure'
	WHEN LOWER(item.label) IN ('paedp') THEN 3014590
	
	
	-- Feeding
	WHEN LOWER(item.label) IN ('diet type') THEN 4043372 --- "Feeding"/Observation/SNOMED

-- 'lvad flow lpm''
	 
	-- Other circulation-related monitoring
	WHEN LOWER(item.label) IN ('central venous pressure', 'cvp' ) THEN 4323687

	-- Neuro parameters
	WHEN LOWER(item.label) IN ('intracranial pressure', 'icp', 'intra cranial pressure') THEN 4353953
	WHEN LOWER(item.label) IN ('cerebral perfusion pressure', 'ccp') THEN 4353710 -- Cerebral perfusion pressure

	-- Other
	WHEN LOWER(item.label) = 'bladder pressure' THEN 4090339
	WHEN LOWER(item.label) = 'abi (r)' THEN 44805247
	WHEN LOWER(item.label) = 'abi (l)' THEN 44805248
	
	ELSE 0
	
  END as measurement_concept_id, 
  CAST ( charttime AS DATE) as measurement_date, 
  CAST ( chartevents.charttime AS TIME) as measurement_time, 
  CASE
	WHEN is_number(CAST(chartevents.icustay_id as TEXT)) = FALSE THEN 0
	ELSE 45877824 -- ICU
  END as measurement_type_concept_id,
  valuenum as value_number,
  value as value_str,
  hadm_id,
    CASE
	-- Clinical assessment
	WHEN LOWER(value) = 'pinpoint' THEN 4061876 -- SNOMED Condition: 'O/E - pinpoint pupils'
	WHEN LOWER(value) = 'fully dilated' THEN 4290615 -- SNOMED Clinical finding: 'Dilatated pupil'
	-- O2 Delivery Methods
	WHEN LOWER(value) = 'none' THEN 45881798 -- LOINC Meas Value: "Room Air" 
	WHEN LOWER(value) = 'face tent' THEN 4138487 -- SNOMED Device: "Face tent oxygen delivery device"
	WHEN LOWER(value) = 't-piece' THEN 4188570 -- SNOMED Device: "T-piece without bag"
	WHEN LOWER(value) = 'nasal cannula' THEN 4224038 -- SNOMED Device: "oxygen Nasal cannula"
	WHEN LOWER(value) = 'non-rebreather' THEN 4145528
	WHEN LOWER(value) = 'aerosol-cool' THEN 4145694 -- SNOMED Device: "aerosol oxygen mask"
	WHEN LOWER(value) = 'ventilator' THEN 40493026 -- SNOMED Device: "mechanical ventilator"
	WHEN LOWER(value) = 'trach mask' THEN 45760219
	WHEN LOWER(value) = 'venti mask' THEN 4322904 -- SNOMED Device: "venturi mask"
	WHEN LOWER(value) = 'bipap mask' THEN 45767334 -- SNOMED Device: "Bipap face mask, single use"
	WHEN LOWER(value) = 'hi flow neb' THEN 4139525 -- SNOMED Device: "high flow oxygen nasal cannula"
	--WHEN LOWER(value1) = ''

	-- Cardiac monitoring
	WHEN LOWER(value) = 'sinus tachy' THEN 4007310
	WHEN LOWER(value) = 'atrial fib' THEN 313217 
	WHEN LOWER(value) = 'sinus brady' THEN 4171683 -- SNOMED Condition for Sinus bradycardia
	WHEN LOWER(value) = 'normal sinus' THEN 4276669 -- SNOMED Condition for Normal sinus 
	WHEN LOWER(value) = '1st deg av block' THEN 314379 -- SNOMED Condition for 'First degree atrioventricular block'
	WHEN LOWER(value) = '2nd deg av block' THEN 318448 -- SNOMED Condition for 'second degree atrioventricular block'
	WHEN LOWER(value) = '2nd avb/mobitz i' THEN 4205137 
	WHEN LOWER(value) = '2nd avb/mobitz ii' THEN 313780 
	WHEN LOWER(value) = 'comp heart block' THEN 40288216
	WHEN LOWER(value) = 'av paced' THEN 4088998 -- SNOMED Measurement for 'AV sequential pacing pattern'
	WHEN LOWER(value) = 'a paced' THEN 4089488 -- SNOMED Measurement for 'Atrial pacing pattern'
	WHEN LOWER(value) = 'v paced' THEN 4092038 -- SNOMED Measurement for 'ventricular pacing pattern'
	WHEN LOWER(value) = 'atrial flutter' THEN 314665
	WHEN LOWER(value) = 'junctional' THEN 4038688 -- SNOMED Condition for 'junctional rhythm'
	WHEN LOWER(value) = 'multfocalatrtach' THEN 0
	WHEN LOWER(value) = 'parox atrial tach' THEN 0
	WHEN LOWER(value) = 'supravent tachy' THEN 4275423
	WHEN LOWER(value) = 'vent. tachy' THEN 4275423
	WHEN LOWER(value) = 'asystole' THEN 4216773
	WHEN LOWER(value) = 'd/c''d' THEN 4132627 -- SNOMED Observation for 'Discontinued' (Mostly for mechanical vent)
	WHEN LOWER(value) = 'tube feeding' THEN 4222605 -- SNOMED Observation / Tube feeding diet
	WHEN LOWER(value) = 'diabetic' THEN 4052041 -- SNOMED Observation / Diabetic diet
	WHEN LOWER(value) = 'full liquid' THEN 4033731 -- SNOMED Obsevation / Liquid diet
	WHEN LOWER(value) = 'clear liquid' THEN 4033731 -- SNOMED Obsevation / Liquid diet (not diferrentiated from full liquid)
	WHEN LOWER(value) = 'npo' THEN 4033731 -- SNOMED Observation / 'nothing by mouth status'
	WHEN LOWER(value) = 'tpn' THEN 45881254 -- LOINC Meas Value / 'TPN' 
	WHEN LOWER(value) = 'renal' THEN 0 -- renal diet
	WHEN LOWER(value) ILIKE '%low cholest' THEN 4215995 -- SNOMED Clinica Obs: Low cholesterol diet
	WHEN LOWER(value) = 'soft solid' THEN 4301609 -- SNOMED Clinica Obs: Soft diet
	ELSE NULL
  END as value_concept_id, 

    CASE 
	--WHEN is_number (CAST( unit_concept_translator.target_concept_id as varchar(20))) = TRUE 
	--	THEN unit_concept_translator.target_concept_id 
	WHEN LOWER(valueuom) = 'mmhg' THEN 8876
	WHEN LOWER(valueuom) = 'deg. f' THEN 9289
	WHEN LOWER(valueuom) = 'deg. c' THEN 8653
	WHEN LOWER(valueuom) = 'l/min' THEN 8698
	WHEN LOWER(valueuom) = 'kg' THEN 9529
	WHEN LOWER(valueuom) = 'bpm' THEN 8541 -- UCUM per minute 
	WHEN LOWER(valueuom) = '%' THEN 8554
	WHEN LOWER(valueuom) = 'cmh2o' THEN 44777590
	WHEN LOWER(valueuom) = 'ml/b' THEN 8587 -- UCUM unit for 'milliliter' (there is no unit avilable for ml per breath but it doesnt really matter...)
	WHEN LOWER(valueuom) = 'torr' THEN 4136788
	WHEN LOWER(label) = 'pupil size r/l' THEN 8588 -- Millimeter 
	ELSE 0 
  END as unit_concept_id, chartevents.itemid as item_id, *

FROM 	
	mimiciii.chartevents_14 as chartevents

INNER JOIN mimiciii.d_items as item on item.itemid = chartevents.itemid 
WHERE chartevents.subject_id > 82000
    ) as temp 
    WHERE lower(temp.label) NOT ILIKE '%alarm%' and lower(temp.label) NOT ILIKE '%gauge%' and lower(temp.label) NOT ILIKE '%threshold%' and lower(temp.label) NOT ILIKE '%wires%' 
     and lower(temp.label) NOT ILIKE '%mdi%'  and lower(temp.label) NOT ILIKE '%pca%' and lower(temp.label) NOT ILIKE '%arctic%' and temp.label NOT ILIKE '%arctic%' 
      and lower(temp.label) NOT ILIKE '%psv%' and lower(temp.label) NOT ILIKE '%ett%' and lower(temp.label) NOT IN ('code status',
       'parameters checked', 'bed bath' , 'called out', 'trach care', 'stool guaiac qc',
       'apnea interval', 'ventilator tank #1', 'unassisted systole', 'assisted systole', 'temporary pacemaker wires ventricular', 
       'cuff presure', 'fspn high', 'vti high', 'ventilator tank #2', 'return pressure', 'filter pressure', 'temporary pacemaker wires atrial',
       'access pressure', 'effluent pressure', 'inspiratory ratio', 'expiratory ratio', 'activity hr', 'activity rr', 'augumented diastole',
       'iabp mean', 'vital cap', 'baedp', 'paedp', 'baedp', 'pinsp (draeger only)', 'baseline current/mA', 'richmond-ras scale') /*and measurement_concept_id = 0*/
       and lower(temp.category) NOT IN ( 'labs', 'alarms', 'skin - impairment', 'treatments', 'adm history/fhpa', 'restraint/support systems', 'access lines - invasive' , 'tandem heart' ,'general' 
       ) 
--ORDER BY random() 
  
/*
Not addressed: 'PCA~', 'code status'

*/
