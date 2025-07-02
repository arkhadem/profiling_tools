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
       sid.value                AS call_stack
FROM   CUDA_GPU_MEMORY_USAGE_EVENTS e

JOIN   CUPTI_ACTIVITY_KIND_RUNTIME  r1
       ON  r1.eventClass    = 1
       AND r1.correlationId = e.correlationId
       AND (r1.globalTid >> 24) = (e.globalPid >> 24)
       AND e.start BETWEEN r1.start AND r1."end"
JOIN   StringIds                      sid ON sid.id = r1.nameId
JOIN   ENUM_CUDA_MEM_KIND             mk ON mk.id = e.memkind
JOIN   ENUM_CUDA_DEV_MEM_EVENT_OPER   op ON op.id = e.memoryOperationType
ORDER  BY start_time;

.quit
