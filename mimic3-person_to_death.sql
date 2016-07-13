
truncate table ohdsi.death;
INSERT into ohdsi.death(person_id, death_date, death_type_concept_id, cause_concept_id, cause_source_concept_id)
SELECT subject_id, CAST(dod as DATE), 0, 0, 0
FROM mimiciii.patients
WHERE patients.expire_flag = 1 and subject_id > 82000
