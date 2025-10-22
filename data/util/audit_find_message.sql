SELECT
    a.audit_id,
    a.message_id,
    a.message_state_id,
    ms.state_title,
    a.audit_on,
    a.audit_by,
    a.reason_why
FROM
    test01.message_audit a
    INNER JOIN test01.message_state ms ON a.message_state_id = ms.message_state_id
WHERE
    CAST(message_id AS VARCHAR) LIKE '0b56e68f%'
ORDER BY
    message_id,
    audit_on ASC
LIMIT
    100