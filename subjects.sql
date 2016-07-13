

truncate table ohdsi.person;

INSERT INTO ohdsi.person(person_id, gender_concept_id, year_of_birth, month_of_birth,day_of_birth,race_concept_id, ethnicity_concept_id, gender_source_value)
SELECT subject_id, 
 CASE
   when sex = 'M' then 8507
   when sex = 'F' then 8532
   else 8851
 END as gender_concept_id, extract (year from dob),extract (month from dob),extract (day from dob),
0,0, sex
FROM mimic2v26.d_patients;
	



