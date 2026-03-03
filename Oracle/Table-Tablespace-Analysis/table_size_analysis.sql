-- ================================================================
-- Oracle Table Size Analysis Query for Oracle 19c
-- Purpose: Find table sizes for specific tables without DBA privileges
-- Author: Generated for Table Size Analysis
-- Date: March 2026
-- Oracle Version: 19c+
-- Compatible with: USER_, ALL_ views (no DBA_ access required)
-- ================================================================

-- Query 1: Table Size for 3 Specific Tables
-- Replace 'TABLE1', 'TABLE2', 'TABLE3' with your actual table names

SELECT 
    owner,
    table_name,
    tablespace_name,
    -- Size in bytes
    bytes,
    -- Size in KB
    ROUND(bytes/1024, 2) AS size_kb,
    -- Size in MB  
    ROUND(bytes/1024/1024, 2) AS size_mb,
    -- Size in GB
    ROUND(bytes/1024/1024/1024, 2) AS size_gb,
    -- Block count
    blocks,
    -- Extents
    extents,
    -- Initial extent size
    initial_extent,
    -- Next extent size  
    next_extent
FROM user_segments
WHERE segment_type = 'TABLE'
AND table_name IN (
    'TABLE1',    -- Replace with your first table name
    'TABLE2',    -- Replace with your second table name
    'TABLE3'     -- Replace with your third table name
)
ORDER BY bytes DESC;

-- ================================================================
-- Alternative Query: If you need to check tables from ALL schemas
-- (where you have SELECT privilege)
-- ================================================================

SELECT 
    owner,
    table_name,
    tablespace_name,
    -- Size in bytes
    bytes,
    -- Size in KB
    ROUND(bytes/1024, 2) AS size_kb,
    -- Size in MB  
    ROUND(bytes/1024/1024, 2) AS size_mb,
    -- Size in GB
    ROUND(bytes/1024/1024/1024, 2) AS size_gb,
    -- Block count
    blocks,
    -- Extents
    extents
FROM all_segments
WHERE segment_type = 'TABLE'
AND (owner, table_name) IN (
    ('SCHEMA1', 'TABLE1'),    -- Replace with schema.table
    ('SCHEMA2', 'TABLE2'),    -- Replace with schema.table
    ('SCHEMA3', 'TABLE3')     -- Replace with schema.table
)
ORDER BY bytes DESC;

-- ================================================================
-- Query 2: Detailed Table Statistics with Row Count
-- Provides additional table information including row counts
-- ================================================================

SELECT 
    t.owner,
    t.table_name,
    t.tablespace_name,
    t.num_rows,
    t.blocks,
    t.avg_row_len,
    -- Estimated size based on statistics
    ROUND((t.num_rows * t.avg_row_len)/1024/1024, 2) AS estimated_size_mb,
    -- Actual size from segments
    ROUND(s.bytes/1024/1024, 2) AS actual_size_mb,
    t.last_analyzed,
    s.extents
FROM all_tables t
JOIN all_segments s ON (t.owner = s.owner AND t.table_name = s.segment_name)
WHERE s.segment_type = 'TABLE'
AND t.table_name IN (
    'TABLE1',    -- Replace with your first table name
    'TABLE2',    -- Replace with your second table name  
    'TABLE3'     -- Replace with your third table name
)
AND t.owner = USER  -- Remove this line if checking other schemas
ORDER BY s.bytes DESC;

-- ================================================================
-- Usage Instructions:
-- 1. Replace 'TABLE1', 'TABLE2', 'TABLE3' with your actual table names
-- 2. For the ALL_SEGMENTS query, replace 'SCHEMA1', etc. with actual schema names
-- 3. Remove "AND t.owner = USER" if you want to check tables in other schemas
-- 4. Run the query that best fits your needs
-- ================================================================