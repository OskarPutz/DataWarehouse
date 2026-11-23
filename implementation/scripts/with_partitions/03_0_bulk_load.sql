-- Compared with without_partitions, this load also stores the calendar date in dbo.CAR_DAY.[Date] (the partitioning column).
USE SigmaPolDW;
GO

-- This is not a production ETL load script; it is a highly simplified demonstration.
-- It only populates the warehouse with the sample data from implementation/bulk (mounted at /dw_data/bulk).
-- CAR_DAY.csv refers to dimensions by business keys; the SCD2 version is chosen by the attributes that create
-- a new version (car: rental point and price category, employee: rental point, client: age category).
-- The CSV files are written in cp1250 and loaded with CODEPAGE = 'RAW' (SQL Server on Linux does not support other code pages).
-- Staging columns use COLLATE DATABASE_DEFAULT (Polish_CI_AS, cp1250), otherwise Polish letters would be lost in tempdb.

SET XACT_ABORT ON;
GO

DROP TABLE IF EXISTS #StageCarDay, #StageClient, #StageEmployee, #StageCar, #StageLocation,
                     #StageJunk, #StageTime, #StageDate;

IF EXISTS (SELECT 1 FROM dbo.LOCATION)
   OR EXISTS (SELECT 1 FROM dbo.CAR)
   OR EXISTS (SELECT 1 FROM dbo.EMPLOYEE)
   OR EXISTS (SELECT 1 FROM dbo.CLIENT)
   OR EXISTS (SELECT 1 FROM dbo.[DATE])
   OR EXISTS (SELECT 1 FROM dbo.[TIME])
   OR EXISTS (SELECT 1 FROM dbo.JUNK)
   OR EXISTS (SELECT 1 FROM dbo.CAR_DAY)
    THROW 50000, 'Target tables must be empty before loading the sample data.', 1;

BEGIN TRY
CREATE TABLE #StageLocation (
    LocationName VARCHAR(40) COLLATE DATABASE_DEFAULT NOT NULL,
    City VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    District VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    Street VARCHAR(30) COLLATE DATABASE_DEFAULT NOT NULL,
    [Status] VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL
);

CREATE TABLE #StageCar (
    LicencePlate VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    LocationName VARCHAR(40) COLLATE DATABASE_DEFAULT NOT NULL,
    Brand VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    Model VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    [Type] VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    FuelType VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    Color VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    ProductionYear SMALLINT NOT NULL,
    PriceCategory VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
    IsCurrent BIT NOT NULL
);

CREATE TABLE #StageEmployee (
    LocationName VARCHAR(40) COLLATE DATABASE_DEFAULT NULL,
    EmployeeNo INT NOT NULL,
    Name VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    Surname VARCHAR(30) COLLATE DATABASE_DEFAULT NOT NULL,
    NameAndSurname VARCHAR(50) COLLATE DATABASE_DEFAULT NOT NULL,
    IsCurrent BIT NOT NULL
);

CREATE TABLE #StageClient (
    PID CHAR(11) COLLATE DATABASE_DEFAULT NOT NULL,
    Name VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    Surname VARCHAR(30) COLLATE DATABASE_DEFAULT NOT NULL,
    NameAndSurname VARCHAR(50) COLLATE DATABASE_DEFAULT NOT NULL,
    Gender VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    DateOfBirth DATE NULL,
    AgeCategory VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    IsCurrent BIT NOT NULL
);

CREATE TABLE #StageDate (
    [Date] DATE NOT NULL,
    [Year] SMALLINT NOT NULL,
    [Quarter] TINYINT NOT NULL,
    [Month] VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    MonthNo TINYINT NOT NULL,
    DayOfWeek VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    DayOfWeekNo TINYINT NOT NULL,
    WorkingDay VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
    Season VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    Vacation VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    Holiday VARCHAR(50) COLLATE DATABASE_DEFAULT NOT NULL,
    BeforeHolidayDay VARCHAR(62) COLLATE DATABASE_DEFAULT NOT NULL
);

CREATE TABLE #StageTime (
    [Hour] TINYINT NULL,
    TimeOfDay VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL
);

CREATE TABLE #StageJunk (
    ReturnStatus VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    RentalLength VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    ServiceType VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
    ServiceKind VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
    MileageCategory VARCHAR(25) COLLATE DATABASE_DEFAULT NOT NULL,
    CarAgeCategory VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL
);

CREATE TABLE #StageCarDay (
    [Date] DATE NOT NULL,
    LicencePlate VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    CarLocationName VARCHAR(40) COLLATE DATABASE_DEFAULT NOT NULL,
    PriceCategory VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
    EmployeeNo INT NOT NULL,
    EmployeeLocationName VARCHAR(40) COLLATE DATABASE_DEFAULT NULL,
    PID CHAR(11) COLLATE DATABASE_DEFAULT NOT NULL,
    ClientAgeCategory VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    IssueHour TINYINT NULL,
    ReturnStatus VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
    RentalLength VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    ServiceType VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
    MileageCategory VARCHAR(25) COLLATE DATABASE_DEFAULT NOT NULL,
    CarAgeCategory VARCHAR(20) COLLATE DATABASE_DEFAULT NOT NULL,
    RentNo INT NULL,
    ServiceNo INT NULL,
    RentedDay TINYINT NOT NULL,
    ServiceDay TINYINT NOT NULL,
    AvailableDay TINYINT NOT NULL,
    IdleDay TINYINT NOT NULL,
    Mileage INT NOT NULL,
    KmDriven DECIMAL(8,2) NOT NULL,
    RentStarted TINYINT NOT NULL,
    RentCost MONEY NOT NULL,
    RentalDays SMALLINT NOT NULL,
    DelayDays SMALLINT NOT NULL,
    ServiceStarted TINYINT NOT NULL,
    ServiceCost MONEY NOT NULL,
    KmSinceLastService INT NOT NULL,
    SurveyAnswered TINYINT NOT NULL,
    CarConditionRating TINYINT NOT NULL,
    IssuesReported TINYINT NOT NULL,
    LikelihoodToRentAgain TINYINT NOT NULL
);

    BEGIN TRANSACTION;

    BULK INSERT #StageLocation
    FROM '/dw_data/bulk/LOCATION.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = 'RAW', TABLOCK);

    BULK INSERT #StageCar
    FROM '/dw_data/bulk/CAR.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = 'RAW', TABLOCK);

    BULK INSERT #StageEmployee
    FROM '/dw_data/bulk/EMPLOYEE.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = 'RAW', TABLOCK);

    BULK INSERT #StageClient
    FROM '/dw_data/bulk/CLIENT.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = 'RAW', TABLOCK);

    BULK INSERT #StageDate
    FROM '/dw_data/bulk/DATE.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = 'RAW', TABLOCK);

    BULK INSERT #StageTime
    FROM '/dw_data/bulk/TIME.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = 'RAW', TABLOCK);

    BULK INSERT #StageJunk
    FROM '/dw_data/bulk/JUNK.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = 'RAW', TABLOCK);

    BULK INSERT #StageCarDay
    FROM '/dw_data/bulk/CAR_DAY.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = 'RAW', TABLOCK);

    INSERT dbo.LOCATION (LocationName, City, District, Street, [Status])
    SELECT LocationName, City, District, Street, [Status]
    FROM #StageLocation;

    INSERT dbo.CAR (Id_Location, LicencePlate, Brand, Model, [Type], FuelType, Color, ProductionYear, PriceCategory, IsCurrent)
    SELECT loc.Id_Location, stage.LicencePlate, stage.Brand, stage.Model, stage.[Type], stage.FuelType, stage.Color,
           stage.ProductionYear, stage.PriceCategory, stage.IsCurrent
    FROM #StageCar AS stage
    JOIN dbo.LOCATION AS loc ON loc.LocationName = stage.LocationName;

    -- The special tuple "not rented" has no rental point (LEFT JOIN gives NULL).
    INSERT dbo.EMPLOYEE (Id_Location, EmployeeNo, Name, Surname, NameAndSurname, IsCurrent)
    SELECT loc.Id_Location, stage.EmployeeNo, stage.Name, stage.Surname, stage.NameAndSurname, stage.IsCurrent
    FROM #StageEmployee AS stage
    LEFT JOIN dbo.LOCATION AS loc ON loc.LocationName = stage.LocationName;

    INSERT dbo.CLIENT (PID, Name, Surname, NameAndSurname, Gender, DateOfBirth, AgeCategory, IsCurrent)
    SELECT PID, Name, Surname, NameAndSurname, Gender, DateOfBirth, AgeCategory, IsCurrent
    FROM #StageClient;

    INSERT dbo.[DATE] ([Date], [Year], [Quarter], [Month], MonthNo, DayOfWeek, DayOfWeekNo, WorkingDay, Season, Vacation, Holiday, BeforeHolidayDay)
    SELECT [Date], [Year], [Quarter], [Month], MonthNo, DayOfWeek, DayOfWeekNo, WorkingDay, Season, Vacation, Holiday, BeforeHolidayDay
    FROM #StageDate;

    INSERT dbo.[TIME] ([Hour], TimeOfDay)
    SELECT [Hour], TimeOfDay
    FROM #StageTime;

    INSERT dbo.JUNK (ReturnStatus, RentalLength, ServiceType, ServiceKind, MileageCategory, CarAgeCategory)
    SELECT ReturnStatus, RentalLength, ServiceType, ServiceKind, MileageCategory, CarAgeCategory
    FROM #StageJunk;

    INSERT dbo.CAR_DAY (Id_Date, [Date], Id_Car, Id_Employee, Id_Client, Id_IssueTime, Id_Junk, RentNo, ServiceNo,
                        RentedDay, ServiceDay, AvailableDay, IdleDay, Mileage, KmDriven, RentStarted, RentCost,
                        RentalDays, DelayDays, ServiceStarted, ServiceCost, KmSinceLastService, SurveyAnswered,
                        CarConditionRating, IssuesReported, LikelihoodToRentAgain)
    SELECT d.Id_Date, d.[Date], car.Id_Car, emp.Id_Employee, client.Id_Client, t.Id_Time, junk.Id_Junk, stage.RentNo, stage.ServiceNo,
           stage.RentedDay, stage.ServiceDay, stage.AvailableDay, stage.IdleDay, stage.Mileage, stage.KmDriven,
           stage.RentStarted, stage.RentCost, stage.RentalDays, stage.DelayDays, stage.ServiceStarted, stage.ServiceCost,
           stage.KmSinceLastService, stage.SurveyAnswered, stage.CarConditionRating, stage.IssuesReported,
           stage.LikelihoodToRentAgain
    FROM #StageCarDay AS stage
    JOIN dbo.[DATE] AS d ON d.[Date] = stage.[Date]
    JOIN dbo.LOCATION AS carLoc ON carLoc.LocationName = stage.CarLocationName
    JOIN dbo.CAR AS car ON car.LicencePlate = stage.LicencePlate
                       AND car.Id_Location = carLoc.Id_Location
                       AND car.PriceCategory = stage.PriceCategory
    LEFT JOIN dbo.LOCATION AS empLoc ON empLoc.LocationName = stage.EmployeeLocationName
    JOIN dbo.EMPLOYEE AS emp ON emp.EmployeeNo = stage.EmployeeNo
                            AND ISNULL(emp.Id_Location, 0) = ISNULL(empLoc.Id_Location, 0)
    JOIN dbo.CLIENT AS client ON client.PID = stage.PID AND client.AgeCategory = stage.ClientAgeCategory
    JOIN dbo.[TIME] AS t ON t.[Hour] = stage.IssueHour OR (t.[Hour] IS NULL AND stage.IssueHour IS NULL)
    JOIN dbo.JUNK AS junk ON junk.ReturnStatus = stage.ReturnStatus
                         AND junk.RentalLength = stage.RentalLength
                         AND junk.ServiceType = stage.ServiceType
                         AND junk.MileageCategory = stage.MileageCategory
                         AND junk.CarAgeCategory = stage.CarAgeCategory;

    IF (SELECT COUNT(*) FROM dbo.CAR_DAY) <> (SELECT COUNT(*) FROM #StageCarDay)
        THROW 50001, 'A car day references a missing dimension tuple.', 1;

    COMMIT TRANSACTION;

    DROP TABLE IF EXISTS #StageCarDay, #StageClient, #StageEmployee, #StageCar, #StageLocation,
                         #StageJunk, #StageTime, #StageDate;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    DROP TABLE IF EXISTS #StageCarDay, #StageClient, #StageEmployee, #StageCar, #StageLocation,
                         #StageJunk, #StageTime, #StageDate;

    THROW;
END CATCH;
GO

-- ===================== Test queries: rows of each table =====================

USE SigmaPolDW;
GO

SELECT * FROM dbo.LOCATION ORDER BY Id_Location;
SELECT * FROM dbo.CAR      ORDER BY Id_Car;
SELECT * FROM dbo.EMPLOYEE ORDER BY Id_Employee;
SELECT * FROM dbo.CLIENT   ORDER BY Id_Client;
SELECT TOP (20) * FROM dbo.[DATE] ORDER BY Id_Date;
SELECT * FROM dbo.[TIME]   ORDER BY Id_Time;
SELECT TOP (20) * FROM dbo.JUNK ORDER BY Id_Junk;
SELECT TOP (20) * FROM dbo.CAR_DAY ORDER BY Id_Car, Id_Date;
GO
