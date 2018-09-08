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
    )
select apr.patientunitstayid as patient_id, apr.apachescore as apache, c.chloride,
       a.ph, a.bun, b.bicarbonate, apr.unabridgedunitlos as los_icu, ap.diedinhospital as death
from apachepatientresult as apr
inner join apacheapsvar as a on a.patientunitstayid = apr.patientunitstayid
inner join apachepredvar as ap on ap.patientunitstayid = apr.patientunitstayid
inner join chloride as c on c.patientunitstayid = apr.patientunitstayid
inner join bicarbonate as b on b.patientunitstayid = apr.patientunitstayid
where apr.apacheversion = 'IVa';