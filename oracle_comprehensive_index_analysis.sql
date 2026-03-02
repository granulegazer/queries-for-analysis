-- ================================================================
-- Oracle Index Status Check Query for Oracle 19c
-- Purpose: Check if indexes are VALID and USABLE for a table
--          Includes both regular indexes and partition indexes
-- Author: Generated for Index Analysis
-- Date: March 2026
-- Oracle Version: 19c+
-- ================================================================

-- Replace 'YOUR_TABLE_NAME' with the actual table name
-- For schema-specific queries, uncomment the schema filter

-- Main Index Status Query
SELECT 
    i.owner AS schema_name,
    i.table_name,
    i.index_name,
    i.index_type,
    i.partitioned,
    
    -- Core Status Checks
    i.status AS index_status,
    
    -- Comprehensive Usability Check
    CASE 
        WHEN i.status = 'VALID' 
            AND i.dropped = 'NO' 
            AND (i.domidx_status IS NULL OR i.domidx_status = 'VALID')
            AND (i.funcidx_status IS NULL OR i.funcidx_status = 'ENABLED')
            THEN 'USABLE'
        ELSE 'UNUSABLE'
    END AS usability_status,
    
    -- Partition Status Summary (for partitioned indexes only)
    CASE 
        WHEN i.partitioned = 'YES' THEN
            (SELECT 
                'Total: ' || COUNT(*) || 
                ' | Usable: ' || SUM(CASE WHEN ip.status = 'USABLE' THEN 1 ELSE 0 END) || 
                ' | Unusable: ' || SUM(CASE WHEN ip.status = 'UNUSABLE' THEN 1 ELSE 0 END)
             FROM dba_ind_partitions ip 
             WHERE ip.index_name = i.index_name AND ip.index_owner = i.owner)
        ELSE 'N/A (Not Partitioned)'
    END AS partition_status_summary,
    
    -- Overall Status Assessment
    CASE 
        WHEN i.status = 'VALID' 
            AND i.dropped = 'NO' 
            AND (i.domidx_status IS NULL OR i.domidx_status = 'VALID')
            AND (i.funcidx_status IS NULL OR i.funcidx_status = 'ENABLED')
            AND (i.partitioned = 'NO' OR 
                 NOT EXISTS (SELECT 1 FROM dba_ind_partitions ip 
                            WHERE ip.index_name = i.index_name 
                            AND ip.index_owner = i.owner 
                            AND ip.status = 'UNUSABLE'))
            THEN 'FULLY OPERATIONAL'
        WHEN i.status = 'VALID' AND i.partitioned = 'YES' 
            AND EXISTS (SELECT 1 FROM dba_ind_partitions ip 
                       WHERE ip.index_name = i.index_name 
                       AND ip.index_owner = i.owner 
                       AND ip.status = 'UNUSABLE')
            THEN 'PARTIALLY OPERATIONAL'
        ELSE 'NOT OPERATIONAL'
    END AS overall_status

FROM dba_indexes i
WHERE UPPER(i.table_name) = UPPER('YOUR_TABLE_NAME')
-- Uncomment the line below to filter by schema
-- AND UPPER(i.owner) = UPPER('YOUR_SCHEMA_NAME')

ORDER BY 
    i.owner, 
    CASE WHEN i.status != 'VALID' THEN 1 ELSE 2 END,  -- Show problematic indexes first
    i.index_name;

-- ================================================================
-- Optional: Detailed Partition Status (if you need partition-level details)
-- Uncomment and run separately for granular partition information
-- ================================================================

/*
SELECT 
    ip.index_owner,
    ip.index_name,
    ip.partition_name,
    ip.status AS partition_status,
    ip.tablespace_name,
    CASE 
        WHEN ip.status = 'UNUSABLE' THEN 'REBUILD PARTITION'
        ELSE 'OK'
    END AS partition_action_needed
    
FROM dba_ind_partitions ip
WHERE EXISTS (
    SELECT 1 FROM dba_indexes i 
    WHERE i.index_name = ip.index_name 
    AND i.owner = ip.index_owner
    AND UPPER(i.table_name) = UPPER('YOUR_TABLE_NAME')
    -- Uncomment the line below to filter by schema
    -- AND UPPER(i.owner) = UPPER('YOUR_SCHEMA_NAME')
)
ORDER BY 
    ip.index_owner,
    ip.index_name,
    ip.partition_position;
*/

-- ================================================================
-- Usage Instructions:
-- 1. Replace 'YOUR_TABLE_NAME' with your actual table name
-- 2. Optionally uncomment schema filtering if needed  
-- 3. Look for:
--    - index_status: Should be 'VALID'
--    - usability_status: Should be 'USABLE' 
--    - overall_status: Should be 'FULLY OPERATIONAL'
-- ================================================================