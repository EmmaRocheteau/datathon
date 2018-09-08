with chloride as (
  select patientunitstayid, max(labresult) as chloride
  from lab
  where labname = 'chloride'
  and labresultrevisedoffset between 0 and 86400
  and labresult between 71 and 137
  group by patientunitstayid
    ),
bicarbonate as (
  select patientunitstayid, avg(labresult) as bicarbonate
  from lab
  where labname = 'bicarbonate'
  and labresultrevisedoffset between 0 and 86400
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
  and labresultrevisedoffset between 0 and 86400
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
  and labresultrevisedoffset between 0 and 86400
  group by patientunitstayid
  ),
worst_creatinine as (
  select patientunitstayid, max(labresult) as creatinine
  from lab
  where labname = 'creatinine'
  group by patientunitstayid
    )
select apr.patientunitstayid as patient_id, apr.apachescore as apache, c.chloride,
       a.ph, a.bun, b.bicarbonate, be.base_excess,
       (wc.creatinine - ic.creatinine) as change_creatinine,
       ap.admitdiagnosis as admit_diagnosis,
       apr.unabridgedunitlos as los_icu, ap.diedinhospital as death
from apachepatientresult as apr
inner join apacheapsvar as a on a.patientunitstayid = apr.patientunitstayid
inner join apachepredvar as ap on ap.patientunitstayid = apr.patientunitstayid
inner join chloride as c on c.patientunitstayid = apr.patientunitstayid
inner join bicarbonate as b on b.patientunitstayid = apr.patientunitstayid
inner join base_excess as be on be.patientunitstayid = apr.patientunitstayid
inner join worst_creatinine as wc on wc.patientunitstayid = apr.patientunitstayid
inner join initial_creatinine as ic on ic.patientunitstayid = apr.patientunitstayid
where apr.apacheversion = 'IVa';