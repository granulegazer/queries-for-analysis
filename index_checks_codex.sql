-- Inputs:
--   :p_table_owner  (schema)
--   :p_table_name   (table)

WITH idx AS (
    SELECT
        i.owner              AS index_owner,
        i.index_name,
        i.table_owner,
        i.table_name,
        i.index_type,
        i.uniqueness,
        i.partitioned,
        i.status             AS index_status,        -- VALID / UNUSABLE / N/A
        i.visibility,
        i.funcidx_status,
        i.domidx_status,
        i.domidx_opstatus,
        i.tablespace_name,
        pi.locality,
        pi.partitioning_type,
        pi.subpartitioning_type,
        o.status             AS object_status        -- VALID / INVALID
    FROM dba_indexes i
    LEFT JOIN dba_part_indexes pi
           ON pi.owner = i.owner
          AND pi.index_name = i.index_name
    LEFT JOIN dba_objects o
           ON o.owner = i.owner
          AND o.object_name = i.index_name
          AND o.object_type = 'INDEX'
    WHERE i.table_owner = UPPER(:p_table_owner)
      AND i.table_name  = UPPER(:p_table_name)
),
part_stat AS (
    SELECT
        p.index_owner,
        p.index_name,
        COUNT(*) AS part_count,
        SUM(CASE WHEN p.status <> 'USABLE' THEN 1 ELSE 0 END) AS unusable_part_count
    FROM dba_ind_partitions p
    GROUP BY p.index_owner, p.index_name
),
subpart_stat AS (
    SELECT
        sp.index_owner,
        sp.index_name,
        COUNT(*) AS subpart_count,
        SUM(CASE WHEN sp.status <> 'USABLE' THEN 1 ELSE 0 END) AS unusable_subpart_count
    FROM dba_ind_subpartitions sp
    GROUP BY sp.index_owner, sp.index_name
)
SELECT
    x.table_owner,
    x.table_name,
    x.index_owner,
    x.index_name,
    x.component_level,                 -- INDEX / PARTITION / SUBPARTITION
    x.partition_name,
    x.subpartition_name,
    x.partition_position,
    x.subpartition_position,
    x.index_type,
    x.uniqueness,
    x.partitioned,
    x.locality,
    x.partitioning_type,
    x.subpartitioning_type,
    x.object_status,                   -- VALID / INVALID
    x.raw_status,                      -- index: VALID/UNUSABLE/N/A, part: USABLE/UNUSABLE
    x.usable_status,                   -- normalized usability
    x.visibility,
    x.funcidx_status,
    x.domidx_status,
    x.domidx_opstatus,
    x.tablespace_name,
    x.last_analyzed
FROM (
    -- INDEX summary row
    SELECT
        i.table_owner,
        i.table_name,
        i.index_owner,
        i.index_name,
        'INDEX' AS component_level,
        CAST(NULL AS VARCHAR2(128)) AS partition_name,
        CAST(NULL AS VARCHAR2(128)) AS subpartition_name,
        CAST(NULL AS NUMBER) AS partition_position,
        CAST(NULL AS NUMBER) AS subpartition_position,
        i.index_type,
        i.uniqueness,
        i.partitioned,
        NVL(i.locality, 'NONPARTITIONED') AS locality,
        i.partitioning_type,
        i.subpartitioning_type,
        i.object_status,
        i.index_status AS raw_status,
        CASE
            WHEN i.partitioned = 'NO' THEN
                CASE i.index_status
                    WHEN 'VALID' THEN 'USABLE'
                    WHEN 'UNUSABLE' THEN 'UNUSABLE'
                    ELSE i.index_status
                END
            WHEN NVL(ps.unusable_part_count,0) + NVL(ss.unusable_subpart_count,0) = 0 THEN 'USABLE'
            WHEN NVL(ps.part_count,0) + NVL(ss.subpart_count,0) = 0 THEN 'UNKNOWN'
            ELSE 'PARTIALLY_UNUSABLE'
        END AS usable_status,
        i.visibility,
        i.funcidx_status,
        i.domidx_status,
        i.domidx_opstatus,
        i.tablespace_name,
        CAST(NULL AS DATE) AS last_analyzed
    FROM idx i
    LEFT JOIN part_stat ps
           ON ps.index_owner = i.index_owner
          AND ps.index_name  = i.index_name
    LEFT JOIN subpart_stat ss
           ON ss.index_owner = i.index_owner
          AND ss.index_name  = i.index_name

    UNION ALL

    -- INDEX PARTITION rows
    SELECT
        i.table_owner,
        i.table_name,
        p.index_owner,
        p.index_name,
        'PARTITION' AS component_level,
        p.partition_name,
        CAST(NULL AS VARCHAR2(128)) AS subpartition_name,
        p.partition_position,
        CAST(NULL AS NUMBER) AS subpartition_position,
        i.index_type,
        i.uniqueness,
        i.partitioned,
        i.locality,
        i.partitioning_type,
        i.subpartitioning_type,
        i.object_status,
        p.status AS raw_status,
        CASE WHEN p.status = 'USABLE' THEN 'USABLE' ELSE 'UNUSABLE' END AS usable_status,
        i.visibility,
        i.funcidx_status,
        i.domidx_status,
        i.domidx_opstatus,
        p.tablespace_name,
        p.last_analyzed
    FROM idx i
    JOIN dba_ind_partitions p
      ON p.index_owner = i.index_owner
     AND p.index_name  = i.index_name

    UNION ALL

    -- INDEX SUBPARTITION rows
    SELECT
        i.table_owner,
        i.table_name,
        sp.index_owner,
        sp.index_name,
        'SUBPARTITION' AS component_level,
        sp.partition_name,
        sp.subpartition_name,
        CAST(NULL AS NUMBER) AS partition_position,
        sp.subpartition_position,
        i.index_type,
        i.uniqueness,
        i.partitioned,
        i.locality,
        i.partitioning_type,
        i.subpartitioning_type,
        i.object_status,
        sp.status AS raw_status,
        CASE WHEN sp.status = 'USABLE' THEN 'USABLE' ELSE 'UNUSABLE' END AS usable_status,
        i.visibility,
        i.funcidx_status,
        i.domidx_status,
        i.domidx_opstatus,
        sp.tablespace_name,
        sp.last_analyzed
    FROM idx i
    JOIN dba_ind_subpartitions sp
      ON sp.index_owner = i.index_owner
     AND sp.index_name  = i.index_name
) x
ORDER BY
    x.index_owner,
    x.index_name,
    CASE x.component_level
        WHEN 'INDEX' THEN 1
        WHEN 'PARTITION' THEN 2
        ELSE 3
    END,
    x.partition_position NULLS FIRST,
    x.subpartition_position NULLS FIRST,
    x.partition_name,
    x.subpartition_name;
