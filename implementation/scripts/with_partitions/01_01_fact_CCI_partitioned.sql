-- Partitioned variant: creates CAR_DAY's CCI on PS_CAR_DAY_Date right after the load (run it after 03_0_bulk_load.sql);
-- without_partitions creates an unpartitioned CCI in its 04_ fact script.
USE SigmaPolDW;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.CAR_DAY')
      AND name = N'CCI_CAR_DAY'
)
BEGIN
    CREATE CLUSTERED COLUMNSTORE INDEX CCI_CAR_DAY
        ON dbo.CAR_DAY
        ORDER ([Date])
        ON PS_CAR_DAY_Date ([Date]);
END;
GO
