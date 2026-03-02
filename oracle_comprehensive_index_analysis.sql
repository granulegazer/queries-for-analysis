-- ================================================================
-- Oracle Index Status Check Query for Oracle 19c
-- Purpose: Check if indexes are VALID and USABLE for a table
-- Author: Generated for Index Analysis
-- Date: March 2026
-- Oracle Version: 19c+
-- ================================================================
-- Replace 'YOUR_TABLE_NAME' with the actual table name
SELECT 
    i.owner,
    i.table_name,
    i.index_name,
    i.index_type,
    i.partitioned,
    -- Index Status (shows N/A for partitioned indexes)
    i.status AS index_status,
    -- Usability Status (the key column you need)
    CASE 
        WHEN i.partitioned = 'NO' THEN
            CASE WHEN i.status = 'VALID' AND i.dropped = 'NO' THEN 'USABLE' ELSE 'UNUSABLE' END
        WHEN i.partitioned = 'YES' THEN
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM dba_ind_partitions p 
                    WHERE p.index_owner = i.owner 
                    AND p.index_name = i.index_name 
                    AND p.status = 'UNUSABLE'
                ) THEN 'UNUSABLE'
                ELSE 'USABLE'
            END
    END AS usability_status,
    -- Partition Details (only for partitioned indexes)
    CASE 
        WHEN i.partitioned = 'YES' THEN
            (SELECT 
                COUNT(*) || ' total, ' ||
                SUM(CASE WHEN p.status = 'USABLE' THEN 1 ELSE 0 END) || ' usable, ' ||
                SUM(CASE WHEN p.status = 'UNUSABLE' THEN 1 ELSE 0 END) || ' unusable'
             FROM dba_ind_partitions p 
             WHERE p.index_owner = i.owner AND p.index_name = i.index_name)
        ELSE 'Not Partitioned'
    END AS partition_summary
FROM dba_indexes i
WHERE UPPER(i.table_name) = UPPER('YOUR_TABLE_NAME')
-- AND UPPER(i.owner) = UPPER('YOUR_SCHEMA_NAME')  -- Uncomment if needed
ORDER BY 
    i.owner,
    CASE WHEN i.partitioned = 'NO' AND i.status != 'VALID' THEN 1 ELSE 2 END,  -- Problems first
    i.index_name;