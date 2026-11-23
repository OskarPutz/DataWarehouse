-- Partitioned variant: defines yearly partitions for CAR_DAY.[Date]; the without_partitions setup has no partition function or scheme.
IF DB_ID(N'SigmaPolDW') IS NULL
    CREATE DATABASE SigmaPolDW COLLATE Polish_CI_AS;
GO

USE SigmaPolDW;
GO

-- Yearly partitions matching the RentMaster data (rents from 2020 to 2026): before 2020, one partition per year 2020-2026,
-- and 2027+ for future days. CAR_DAY has one row per car and day, so every year of data is one partition.
CREATE PARTITION FUNCTION PF_CAR_DAY_Date (DATE)
AS RANGE RIGHT FOR VALUES ('20200101', '20210101', '20220101', '20230101', '20240101', '20250101', '20260101', '20270101');
GO

CREATE PARTITION SCHEME PS_CAR_DAY_Date
AS PARTITION PF_CAR_DAY_Date ALL TO ([PRIMARY]);
GO

-- ALL TO ([PRIMARY]) maps every partition to the PRIMARY filegroup: the partitions are logically separate
-- (queries filtered by date read only the needed years, old years can be switched out or rebuilt separately),
-- but they are not spread across different filegroups or disks.
