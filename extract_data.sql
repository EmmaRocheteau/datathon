select apr.patientunitstayid as patient_id, apr.apachescore as apache,
       apr.unabridgedunitlos as los_icu, ap.diedinhospital as death
from apachepatientresult as apr
inner join apacheapsvar as a on a.patientunitstayid = apr.patientunitstayid
inner join apachepredvar as ap on ap.patientunitstayid = apr.patientunitstayid
where apr.apacheversion = 'IVa';