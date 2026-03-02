# Oracle Index Analysis Queries for Oracle 19c

This repository contains comprehensive Oracle SQL queries designed to analyze indexes and partitioned indexes, specifically optimized for Oracle 19c.

## Files Included

### 1. `oracle_comprehensive_index_analysis.sql`
**Purpose**: Exhaustive index analysis with detailed information
**Use Case**: Deep analysis, performance tuning, maintenance planning

**Features:**
- Complete index metadata and status
- Partition and subpartition details
- Index health scoring
- Performance metrics and efficiency calculations
- Detailed recommendations
- Statistics freshness analysis

### 2. `oracle_quick_index_check.sql`
**Purpose**: Quick index status verification
**Use Case**: Daily checks, rapid troubleshooting

**Features:**
- Essential index status information
- Quick usability check
- Partition summary
- Basic recommendations

## How to Use

### Step 1: Choose Your Query
- Use **comprehensive** query for detailed analysis
- Use **quick** query for routine checks

### Step 2: Modify the Query
Replace `'YOUR_TABLE_NAME'` with your actual table name:
```sql
WHERE UPPER(i.table_name) = UPPER('EMPLOYEES')
```

### Step 3: Optional Schema Filtering
If you need to filter by schema, uncomment and modify:
```sql
-- AND UPPER(i.owner) = UPPER('HR')
```

### Step 4: Execute and Analyze Results

## Key Output Columns Explained

### Status Fields
- **index_status**: VALID/INVALID - Core index validity
- **usability_status**: USABLE/UNUSABLE - Whether index can be used by queries
- **health_status**: HEALTHY/NEEDS_STATS/PROBLEMATIC - Overall index health

### Partition Information
- **is_partitioned**: YES/NO - Whether index is partitioned
- **partition_count**: Total number of partitions
- **usable_partitions**: Number of usable partitions
- **unusable_partitions**: Number of unusable partitions
- **unusable_partition_list**: Names of unusable partitions

### Performance Metrics
- **clustering_factor**: Lower is better for range scans
- **avg_rows_per_key**: Selectivity indicator
- **btree_level**: Index depth (lower is generally better)

## Oracle 19c Specific Features

This query leverages Oracle 19c enhancements:

1. **Enhanced Statistics**: Uses newer statistics columns
2. **Improved Partitioning**: Supports all 19c partition types
3. **Advanced Indexing**: Includes invisible indexes and function-based indexes
4. **Orphaned Entries**: Detects orphaned index entries (19c feature)

## Common Scenarios

### Scenario 1: Table Performance Issues
```sql
-- Look for high clustering factor or unusable indexes
-- Focus on recommendation column
```

### Scenario 2: Partition Maintenance
```sql
-- Check unusable_partitions > 0
-- Review unusable_partition_list for rebuild targets
```

### Scenario 3: Statistics Freshness
```sql
-- Check last_analyzed dates
-- Look for 'NEEDS_STATS' in health_status
```

## Troubleshooting Guide

### Index Status Issues

| Status | Meaning | Action |
|--------|---------|--------|
| INVALID | Index is corrupted or inconsistent | `ALTER INDEX index_name REBUILD` |
| UNUSABLE | Index cannot be used by optimizer | `ALTER INDEX index_name REBUILD` |
| NEEDS_STATS | Statistics are stale | `EXEC DBMS_STATS.GATHER_INDEX_STATS` |

### Partition Issues

| Issue | Action |
|-------|--------|
| Unusable Partitions | `ALTER INDEX index_name REBUILD PARTITION partition_name` |
| Missing Statistics | `EXEC DBMS_STATS.GATHER_INDEX_STATS(partition_name => 'part_name')` |

## Performance Considerations

### For Large Tables (> 1M rows)
- Use the quick check query first
- Run comprehensive analysis during maintenance windows
- Consider parallel execution for partition rebuilds

### For Partitioned Tables
- Focus on partition-level statistics
- Monitor partition pruning effectiveness
- Consider local vs global index trade-offs

## Best Practices

### Regular Monitoring
1. Run quick check daily
2. Run comprehensive analysis weekly
3. Monitor recommendations column for proactive maintenance

### Maintenance Planning
1. Rebuild indexes with high clustering factor
2. Update statistics for indexes with stale stats
3. Address unusable partitions promptly

### Oracle 19c Optimization
1. Leverage invisible indexes for testing
2. Use hybrid columnar compression where applicable
3. Consider automatic indexing features (if licensed)

## Security Notes

- These queries use DBA_* views requiring DBA privileges
- For limited access, modify to use USER_* or ALL_* views
- Consider creating views with appropriate access controls

## Sample Output Interpretation

```
INDEX_NAME: IX_EMPLOYEES_DEPT_ID
INDEX_STATUS: VALID
USABILITY_STATUS: USABLE
HEALTH_STATUS: NEEDS_STATS
PARTITION_COUNT: 12
UNUSABLE_PARTITIONS: 2
RECOMMENDATION: REBUILD UNUSABLE PARTITIONS
```

**Interpretation**: Index is valid but has 2 unusable partitions that need rebuilding, and statistics should be updated.

## Version Compatibility

- **Optimized for**: Oracle 19c (19.3+)
- **Compatible with**: Oracle 18c, 21c, 23c
- **Limited compatibility**: Oracle 12c (some columns may not exist)

## Support

For Oracle-specific questions, consult:
- Oracle Documentation 19c
- Oracle Support (My Oracle Support)
- Oracle Community Forums

---

**Note**: Always test queries in development environment before production use.