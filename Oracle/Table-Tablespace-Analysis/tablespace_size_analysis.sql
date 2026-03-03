-- ================================================================
-- Oracle Tablespace Size Analysis Query for Oracle 19c
-- Purpose: Find tablespace sizes and usage without DBA privileges
-- Author: Generated for Tablespace Analysis
-- Date: March 2026
-- Oracle Version: 19c+
-- Compatible with: USER_, ALL_ views (no DBA_ access required)
-- ================================================================

-- Query 1: Current User's Tablespace Usage Summary
-- Shows tablespace usage for tablespaces accessible to current user

SELECT 
    tablespace_name,
    -- Total allocated space
    ROUND(SUM(bytes)/1024/1024, 2) AS total_allocated_mb,
    ROUND(SUM(bytes)/1024/1024/1024, 2) AS total_allocated_gb,
    -- Used space (from segments)
    ROUND(SUM(CASE WHEN segment_type IS NOT NULL THEN bytes ELSE 0 END)/1024/1024, 2) AS used_mb,
    -- Free space calculation
    ROUND((SUM(bytes) - SUM(CASE WHEN segment_type IS NOT NULL THEN bytes ELSE 0 END))/1024/1024, 2) AS estimated_free_mb,
    -- Usage percentage
    ROUND(
        (SUM(CASE WHEN segment_type IS NOT NULL THEN bytes ELSE 0 END) / SUM(bytes)) * 100, 2
    ) AS usage_percentage,
    -- Number of segments
    COUNT(CASE WHEN segment_type IS NOT NULL THEN 1 END) AS segment_count
FROM user_segments
GROUP BY tablespace_name
ORDER BY SUM(bytes) DESC;

-- ================================================================
-- Query 2: Detailed Tablespace Analysis with Free Space
-- Uses USER_FREE_SPACE for more accurate free space information
-- ================================================================

WITH tablespace_usage AS (
    -- Get used space from segments
    SELECT 
        tablespace_name,
        SUM(bytes) AS used_bytes
    FROM user_segments
    GROUP BY tablespace_name
),
tablespace_free AS (
    -- Get free space
    SELECT 
        tablespace_name,
        SUM(bytes) AS free_bytes
    FROM user_free_space
    GROUP BY tablespace_name
)
SELECT 
    COALESCE(tu.tablespace_name, tf.tablespace_name) AS tablespace_name,
    -- Used space
    ROUND(NVL(tu.used_bytes, 0)/1024/1024, 2) AS used_mb,
    -- Free space
    ROUND(NVL(tf.free_bytes, 0)/1024/1024, 2) AS free_mb,
    -- Total space
    ROUND((NVL(tu.used_bytes, 0) + NVL(tf.free_bytes, 0))/1024/1024, 2) AS total_mb,
    -- Usage percentage
    ROUND(
        CASE 
            WHEN (NVL(tu.used_bytes, 0) + NVL(tf.free_bytes, 0)) > 0 THEN
                (NVL(tu.used_bytes, 0) / (NVL(tu.used_bytes, 0) + NVL(tf.free_bytes, 0))) * 100
            ELSE 0
        END, 2
    ) AS usage_percentage,
    -- Free percentage
    ROUND(
        CASE 
            WHEN (NVL(tu.used_bytes, 0) + NVL(tf.free_bytes, 0)) > 0 THEN
                (NVL(tf.free_bytes, 0) / (NVL(tu.used_bytes, 0) + NVL(tf.free_spaces, 0))) * 100
            ELSE 0
        END, 2
    ) AS free_percentage
FROM tablespace_usage tu
FULL OUTER JOIN tablespace_free tf ON tu.tablespace_name = tf.tablespace_name
ORDER BY (NVL(tu.used_bytes, 0) + NVL(tf.free_bytes, 0)) DESC;

-- ================================================================
-- Query 3: Tablespace Usage by Object Type
-- Shows what types of objects are using space in each tablespace
-- ================================================================

SELECT 
    tablespace_name,
    segment_type,
    -- Count of objects
    COUNT(*) AS object_count,
    -- Total space used by object type
    ROUND(SUM(bytes)/1024/1024, 2) AS total_mb,
    -- Average object size
    ROUND(AVG(bytes)/1024/1024, 2) AS avg_object_size_mb,
    -- Percentage of tablespace used by this object type
    ROUND(
        (SUM(bytes) / SUM(SUM(bytes)) OVER (PARTITION BY tablespace_name)) * 100, 2
    ) AS pct_of_tablespace
FROM user_segments
GROUP BY tablespace_name, segment_type
ORDER BY tablespace_name, SUM(bytes) DESC;

-- ================================================================
-- Query 4: Quick Tablespace Summary (One-liner result)
-- Simple summary for quick checks
-- ================================================================

SELECT 
    COUNT(DISTINCT tablespace_name) AS tablespace_count,
    ROUND(SUM(bytes)/1024/1024, 2) AS total_used_mb,
    ROUND(SUM(bytes)/1024/1024/1024, 2) AS total_used_gb,
    COUNT(*) AS total_segments
FROM user_segments;

-- ================================================================
-- Query 5: Largest Objects in Each Tablespace
-- Shows the biggest space consumers
-- ================================================================

SELECT *
FROM (
    SELECT 
        tablespace_name,
        segment_type,
        segment_name,
        ROUND(bytes/1024/1024, 2) AS size_mb,
        blocks,
        extents,
        ROW_NUMBER() OVER (PARTITION BY tablespace_name ORDER BY bytes DESC) AS rn
    FROM user_segments
) 
WHERE rn <= 5  -- Top 5 largest objects per tablespace
ORDER BY tablespace_name, rn;

-- ================================================================
-- Usage Instructions:
-- 1. Run Query 1 for a quick overview of tablespace usage
-- 2. Run Query 2 for detailed usage with free space information  
-- 3. Run Query 3 to see what object types are using space
-- 4. Run Query 4 for a simple summary
-- 5. Run Query 5 to identify the largest space consumers
--
-- Note: These queries show information for tablespaces that contain
-- objects owned by the current user. For system-wide tablespace
-- information, DBA privileges would be required.
-- ================================================================