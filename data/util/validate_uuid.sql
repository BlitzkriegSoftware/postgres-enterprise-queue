-- https://datacraze.io/sql-cast-exception-handling/

with validated_uuids as (
      select value,
             value ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' as is_valid
      from (values ('7492bd12-1fff-4d02-9355-da5678d2da'), -- not valid UUID
                   ('7492bd12-1fff-4d02-9355-da5678d2da46') -- valid UUID
      ) as t(value)
    )
    select case when is_valid then value::uuid end
      from validated_uuids;