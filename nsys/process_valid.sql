.headers on
.mode    tabs

WITH chosen AS (
  SELECT  e.globalPid,
          e.address,
          e.start          AS start_time,
          e.bytes,
          e.memkind,
          e.memoryOperationType,
          e.name           AS var_name,
          r67.callchainId
  FROM    CUDA_GPU_MEMORY_USAGE_EVENTS   e
  JOIN    CUPTI_ACTIVITY_KIND_RUNTIME    r67
         ON  r67.eventClass    = 67
         AND r67.correlationId = e.correlationId
         AND (r67.globalTid >> 24) = (e.globalPid >> 24)
         AND e.start BETWEEN r67.start AND r67."end"
),

stacktxt AS (
  SELECT  cc.id  AS callchainId,
          group_concat(sym.value || '(' || mod.value || ')', ' -> ') AS stack
  FROM    CUDA_CALLCHAINS cc
  JOIN    StringIds       sym ON sym.id = cc.symbol
  JOIN    StringIds       mod ON mod.id = cc.module
  WHERE   cc.id IN (SELECT DISTINCT callchainId FROM chosen)
  GROUP   BY cc.id
)

SELECT  c.globalPid                    AS PID,
        c.address,
        c.start_time,
        c.bytes,
        mk.name                        AS memkind,
        op.name                        AS mem_op_type,
        c.var_name,
        s.stack                        AS call_stack
FROM    chosen               c
LEFT JOIN stacktxt           s   USING (callchainId)
JOIN    ENUM_CUDA_MEM_KIND   mk  ON mk.id = c.memkind
JOIN    ENUM_CUDA_DEV_MEM_EVENT_OPER op ON op.id = c.memoryOperationType
ORDER BY c.start_time;

.quit
