-- ================================================================
-- Quick Oracle Index Status Check Query for Oracle 19c
-- Purpose: Simple query for quick index status verification
-- ================================================================

-- Replace 'YOUR_TABLE_NAME' with the actual table name
SELECT 
    i.owner AS schema_name,
    i.table_name,
    i.index_name,
    i.index_type,
    i.uniqueness,
    i.status AS index_status,
    i.partitioned,
    
    -- Quick usability check
    CASE 
        WHEN i.status = 'VALID' AND i.dropped = 'NO' 
            AND (i.domidx_status IS NULL OR i.domidx_status = 'VALID')
            AND (i.funcidx_status IS NULL OR i.funcidx_status = 'ENABLED')
            THEN 'USABLE'
        ELSE 'UNUSABLE'
    END AS usability_status,
    
    -- Partition status (if applicable)
    CASE 
        WHEN i.partitioned = 'YES' THEN
            (SELECT 
                TO_CHAR(COUNT(*)) || ' Total, ' ||
                TO_CHAR(SUM(CASE WHEN ip.status = 'USABLE' THEN 1 ELSE 0 END)) || ' Usable, ' ||
                TO_CHAR(SUM(CASE WHEN ip.status = 'UNUSABLE' THEN 1 ELSE 0 END)) || ' Unusable'
             FROM dba_ind_partitions ip 
             WHERE ip.index_name = i.index_name AND ip.index_owner = i.owner)
        ELSE 'N/A (Not Partitioned)'
    END AS partition_summary,
    
    -- Index columns
    (SELECT LISTAGG(ic.column_name, ', ') WITHIN GROUP (ORDER BY ic.column_position)
     FROM dba_ind_columns ic 
     WHERE ic.index_name = i.index_name AND ic.index_owner = i.owner) AS index_columns,
    
    i.tablespace_name,
    i.last_analyzed,
    
    -- Simple recommendation
    CASE 
        WHEN i.status != 'VALID' OR i.dropped = 'YES' THEN 'REBUILD INDEX'
        WHEN i.last_analyzed IS NULL THEN 'GATHER STATISTICS'
        WHEN i.partitioned = 'YES' AND EXISTS (
            SELECT 1 FROM dba_ind_partitions ip 
            WHERE ip.index_name = i.index_name 
            AND ip.index_owner = i.owner 
            AND ip.status = 'UNUSABLE'
        ) THEN 'REBUILD UNUSABLE PARTITIONS'
        ELSE 'OK'
    END AS quick_recommendation

FROM dba_indexes i
WHERE UPPER(i.table_name) = UPPER('YOUR_TABLE_NAME')
-- Uncomment the line below if you need to filter by schema
-- AND UPPER(i.owner) = UPPER('YOUR_SCHEMA_NAME')

ORDER BY i.owner, i.index_name;