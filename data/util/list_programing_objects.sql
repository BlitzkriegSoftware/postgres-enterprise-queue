select routine_type, routine_name from information_schema.routines 
where specific_schema = 'test01'
order by routine_name
;