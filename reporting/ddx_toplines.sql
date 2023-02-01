select
state_code
-- some of the contact types are separated by
-- colons and followed by more detail, which we don't care about, so just grab the first part
, replace(replace(case when contact_type_name like '%:%' then split_part(contact_type_name, ': ' , 1)
-- Collapse Walk and Canvass into just Walk
else contact_type_name end, 'Walk', 'Canvass'),
-- Collapse SMS Text and Text into just Text
'SMS Text', 'Text') as mode
, count(*) as attempts
-- count these responses as contacted: Canvassed, Called, Texted
, sum(case when (case when contact_result_name like '%:%' then split_part(contact_result_name, ': ' , 2) else contact_result_name end) in ('Canvassed', 'Called', 'Texted') then 1 else 0 end) as contacts
from phoenix_demsddx_from_ddx.contact_attempt_delivery_base
-- Contact in 2022
where datetime_canvassed_window_start in ( '2022-07-01T00:00:00+00:00')
and state_code in ('AZ', 'CO', 'FL', 'GA', 'NC', 'NV', 'NH', 'OH', 'PA', 'WI')
group by 1,2 order by 1,2;
