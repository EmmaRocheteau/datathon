drop materialized view if exists sepsis_patients cascade;
create materialized view sepsis_patients as
  select patientunitstayid
  from diagnosis
  where diagnosisstring like '%sepsis%'
  or diagnosisstring like '%septic%';

-- we want to avoid matching all trauma because otherwise it matches all burns/trauma
-- e.g. we would not want to include 'burns/trauma|dermatology|rash, infectious'
drop materialized view if exists trauma_patients cascade;
create materialized view trauma_patients as
  select patientunitstayid
  from diagnosis
  where diagnosisstring like '%trauma - %'
  or diagnosisstring like '%trauma-%'
  or diagnosisstring like '% trauma%';

drop materialized view if exists abdominal_surgery cascade;
create materialized view abdominal_surgery as
  select patientunitstayid
  from treatment
  where treatmentstring like '%gastrointestinal%surgery%';

drop materialized view if exists dialysis cascade;
create materialized view dialysis as
  select patientunitstayid
  from treatment
  where treatmentstring like '%renal%dialysis%';

drop materialized view if exists desired_cohort cascade;
create materialized view desired_cohort as
with chloride as (
  select patientunitstayid, max(labresult) as chloride
  from lab
  where labname = 'chloride'
  and labresultrevisedoffset between 0 and 1440
  and labresult between 71.0 and 137.0
  group by patientunitstayid
  ),
bicarbonate as (
  select patientunitstayid, avg(labresult) as bicarbonate
  from lab
  where labname in ('bicarbonate', 'HCO3')
  and labresultrevisedoffset between 0 and 1440
  and labresult between 8.9 and 44.0
  group by patientunitstayid
  ),
base_excess_ungrouped as (
  select patientunitstayid,
    case
      when labname = 'Base Deficit' then - labresult
      else labresult
      end as base_excess
  from lab
  where labname in ('Base Deficit', 'Base Excess')
  and labresultrevisedoffset between 0 and 1440
  ),
base_excess as (
  select patientunitstayid, min(base_excess) as base_excess
  from base_excess_ungrouped
  where base_excess between -22.8 and 20.0
  group by patientunitstayid
  ),
initial_creatinine as (
  select patientunitstayid, max(labresult) as creatinine
  from lab
  where labname = 'creatinine'
  and labresultrevisedoffset between 0 and 1440
  group by patientunitstayid
  ),
pH as (
  select patientunitstayid, avg(labresult) as pH
  from lab
  where labname = 'pH'
  and labresultrevisedoffset between 0 and 1440
  group by patientunitstayid
  ),
worst_creatinine as (
  select patientunitstayid, max(labresult) as creatinine
  from lab
  where labname = 'creatinine'
  group by patientunitstayid
  )
select apr.patientunitstayid as patient_id, apr.apachescore as apache, c.chloride,
       ph.ph, a.bun, b.bicarbonate, be.base_excess,
       (wc.creatinine - ic.creatinine) as change_creatinine,
       case
         when apr.patientunitstayid in (select * from sepsis_patients)
           then 1
         else 0
         end as sepsis,
       case
         when apr.patientunitstayid in (select * from trauma_patients)
           then 1
         else 0
         end as trauma,
       case
         when apr.patientunitstayid in (select * from abdominal_surgery)
           then 1
         else 0
         end as abdom_surg,
       ap.admitdiagnosis as admit_diagnosis,
       apr.unabridgedunitlos as los_icu,
       case
         when apr.patientunitstayid in (select * from dialysis)
           then 1
         else 0
         end as rrt,
       ap.diedinhospital as death
from apachepatientresult as apr
inner join apacheapsvar as a on a.patientunitstayid = apr.patientunitstayid
inner join apachepredvar as ap on ap.patientunitstayid = apr.patientunitstayid
inner join chloride as c on c.patientunitstayid = apr.patientunitstayid
inner join bicarbonate as b on b.patientunitstayid = apr.patientunitstayid
inner join base_excess as be on be.patientunitstayid = apr.patientunitstayid
inner join worst_creatinine as wc on wc.patientunitstayid = apr.patientunitstayid
inner join initial_creatinine as ic on ic.patientunitstayid = apr.patientunitstayid
inner join pH as ph on ph.patientunitstayid = apr.patientunitstayid
where apr.apacheversion = 'IVa'
and a.bun > 0
and ap.age > 15;