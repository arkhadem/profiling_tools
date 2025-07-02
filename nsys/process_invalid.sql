.headers on
.mode    tabs

SELECT
       e.globalPid              AS PID,
       e.address,
       e.start                  AS start_time,
       e.bytes,
       mk.name                  AS memkind,
       op.name                  AS mem_op_type,
       e.name                   AS var_name,
       'STACK_NOT_FOUND'        AS call_stack
FROM   CUDA_GPU_MEMORY_USAGE_EVENTS e

LEFT   JOIN CUPTI_ACTIVITY_KIND_RUNTIME r
       ON  r.correlationId = e.correlationId
       AND (r.globalTid >> 24) = (e.globalPid >> 24)
       AND e.start BETWEEN r.start AND r."end"
       AND r.eventClass IN (1, 67)
JOIN   ENUM_CUDA_MEM_KIND            mk ON mk.id = e.memkind
JOIN   ENUM_CUDA_DEV_MEM_EVENT_OPER  op ON op.id = e.memoryOperationType
WHERE  r.rowid IS NULL
ORDER  BY start_time;

.quit
