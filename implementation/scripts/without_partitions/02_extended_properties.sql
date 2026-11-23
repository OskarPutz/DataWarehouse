-- Extended Properties are used to add descriptions to tables and columns in SQL Server. These descriptions can be viewed in SQL Server Management Studio (SSMS) and can help developers and analysts understand the purpose of each table and column in the database.
-- https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/extended-properties-catalog-views-sys-extended-properties?view=sql-server-ver17
-- Table and column descriptions (MS_Description) for SigmaPol DW
USE SigmaPolDW;
GO

-- Adds or updates MS_Description; @columnName = NULL describes the table or view itself.
CREATE OR ALTER PROCEDURE dbo.SetDesc @objectName SYSNAME, @columnName SYSNAME = NULL, @description NVARCHAR(3750)
AS
BEGIN
  DECLARE @object_id INT = OBJECT_ID(N'dbo.' + QUOTENAME(@objectName));
  DECLARE @l1t NVARCHAR(128);
  SELECT @l1t = CASE type WHEN 'V' THEN N'VIEW' WHEN 'U' THEN N'TABLE' END
  FROM sys.objects
  WHERE object_id = @object_id;

  IF @l1t IS NULL
    THROW 50000, 'The specified dbo object does not exist or is not a table or view.', 1;

  -- COLUMNPROPERTY resolves columns for both tables and views.
  DECLARE @minor INT = CASE WHEN @columnName IS NULL THEN 0 ELSE COLUMNPROPERTY(@object_id, @columnName, 'ColumnId') END;
  IF @columnName IS NOT NULL AND @minor IS NULL
    THROW 50001, 'The specified column does not exist on the dbo object.', 1;

  DECLARE @exists BIT = CASE WHEN EXISTS (SELECT 1 FROM sys.extended_properties
                                          WHERE class = 1 AND name = N'MS_Description'
                                            AND major_id = @object_id AND minor_id = @minor)
                             THEN 1 ELSE 0 END;
  DECLARE @l2t VARCHAR(128) = CASE WHEN @columnName IS NULL THEN NULL ELSE 'COLUMN' END;

    IF @exists = 1
        EXEC sys.sp_updateextendedproperty @name = N'MS_Description', @value = @description,
             @level0type = N'SCHEMA', @level0name = N'dbo',
             @level1type = @l1t,      @level1name = @objectName,
             @level2type = @l2t,      @level2name = @columnName;
    ELSE
        EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = @description,
             @level0type = N'SCHEMA', @level0name = N'dbo',
             @level1type = @l1t,      @level1name = @objectName,
             @level2type = @l2t,      @level2name = @columnName;
END;
GO

-- ===================== CAR_DAY =====================
EXEC dbo.SetDesc N'CAR_DAY', NULL, N'Fact table. One tuple describes the state of one car of the fleet on one day: rented, in the service or idle. The rent and the service starting on this day are also described in this tuple.';
EXEC dbo.SetDesc N'CAR_DAY', N'Id_Date',               N'FK to DATE. Day described by the tuple.';
EXEC dbo.SetDesc N'CAR_DAY', N'Id_Car',                N'FK to CAR. Car described by the tuple.';
EXEC dbo.SetDesc N'CAR_DAY', N'Id_Employee',           N'FK to EMPLOYEE. Employee who handled the rent the car is in on this day ("not rented" if the car is not rented).';
EXEC dbo.SetDesc N'CAR_DAY', N'Id_Client',             N'FK to CLIENT. Client who rents the car on this day ("not rented" if the car is not rented).';
EXEC dbo.SetDesc N'CAR_DAY', N'Id_IssueTime',          N'FK to TIME. Issue time of the rent starting on this day ("no rent" if no rent starts on this day).';
EXEC dbo.SetDesc N'CAR_DAY', N'Id_Junk',               N'FK to JUNK. Junk attributes.';
EXEC dbo.SetDesc N'CAR_DAY', N'RentNo',                N'Number of the rent the car is in on this day (NULL if the car is not rented).';
EXEC dbo.SetDesc N'CAR_DAY', N'ServiceNo',             N'Number of the service the car is in on this day (NULL if the car is not in the service).';
EXEC dbo.SetDesc N'CAR_DAY', N'RentedDay',             N'1 if the car is rented on this day, otherwise 0.';
EXEC dbo.SetDesc N'CAR_DAY', N'ServiceDay',            N'1 if the car is in the service on this day, otherwise 0.';
EXEC dbo.SetDesc N'CAR_DAY', N'AvailableDay',          N'1 if the car is available for rental on this day (not in the service), otherwise 0.';
EXEC dbo.SetDesc N'CAR_DAY', N'IdleDay',               N'1 if the car is available but not rented on this day, otherwise 0.';
EXEC dbo.SetDesc N'CAR_DAY', N'Mileage',               N'Mileage of the car at the beginning of the day in km.';
EXEC dbo.SetDesc N'CAR_DAY', N'KmDriven',              N'Number of kilometres driven on this day (km of the rent divided by its days).';
EXEC dbo.SetDesc N'CAR_DAY', N'RentStarted',           N'1 if a rent of the car is issued on this day, otherwise 0.';
EXEC dbo.SetDesc N'CAR_DAY', N'RentCost',              N'Total cost of the rent issued on this day (0 if no rent is issued).';
EXEC dbo.SetDesc N'CAR_DAY', N'RentalDays',            N'Number of days of the rent issued on this day (0 if no rent is issued).';
EXEC dbo.SetDesc N'CAR_DAY', N'DelayDays',             N'Number of days the rent issued on this day was returned after the planned return date.';
EXEC dbo.SetDesc N'CAR_DAY', N'ServiceStarted',        N'1 if a service of the car starts on this day, otherwise 0.';
EXEC dbo.SetDesc N'CAR_DAY', N'ServiceCost',           N'Total cost of the service starting on this day (0 if no service starts).';
EXEC dbo.SetDesc N'CAR_DAY', N'KmSinceLastService',    N'Kilometres driven since the previous service, for the service starting on this day (0 if no service starts).';
EXEC dbo.SetDesc N'CAR_DAY', N'SurveyAnswered',        N'1 if the client answered the post-rental survey for the rent issued on this day, otherwise 0.';
EXEC dbo.SetDesc N'CAR_DAY', N'CarConditionRating',    N'Client''s rating of the overall condition of the car (1-5) for the rent issued on this day (0 if no survey).';
EXEC dbo.SetDesc N'CAR_DAY', N'IssuesReported',        N'1 if the client experienced mechanical issues during the rent issued on this day, otherwise 0.';
EXEC dbo.SetDesc N'CAR_DAY', N'LikelihoodToRentAgain', N'How likely the client is to rent this car model again (1-5) for the rent issued on this day (0 if no survey).';

-- ===================== CAR =====================
EXEC dbo.SetDesc N'CAR', NULL, N'Dimension table (SCD2). One tuple describes one car of the fleet, assigned to one rental point, within one price category.';
EXEC dbo.SetDesc N'CAR', N'Id_Car',         N'PK. Surrogate key.';
EXEC dbo.SetDesc N'CAR', N'Id_Location',    N'FK to LOCATION. Rental point the car is assigned to.';
EXEC dbo.SetDesc N'CAR', N'LicencePlate',   N'Business key. Licence plate of the car.';
EXEC dbo.SetDesc N'CAR', N'Brand',          N'Brand of the car.';
EXEC dbo.SetDesc N'CAR', N'Model',          N'Model of the car.';
EXEC dbo.SetDesc N'CAR', N'Type',           N'Type of the car: suv, van, combi, sedan, coupe, sport.';
EXEC dbo.SetDesc N'CAR', N'FuelType',       N'Fuel type of the car: petrol, diesel, LPG, electric, hybrid.';
EXEC dbo.SetDesc N'CAR', N'Color',          N'Color of the car.';
EXEC dbo.SetDesc N'CAR', N'ProductionYear', N'Year of the car production.';
EXEC dbo.SetDesc N'CAR', N'PriceCategory',  N'Price category based on the daily price: economy (< 200), standard (< 300), premium (< 400), luxury (>= 400).';
EXEC dbo.SetDesc N'CAR', N'IsCurrent',      N'1 if information is current, otherwise 0 (SCD2).';

-- ===================== LOCATION =====================
EXEC dbo.SetDesc N'LOCATION', NULL, N'Dimension table. One tuple describes one rental point.';
EXEC dbo.SetDesc N'LOCATION', N'Id_Location',  N'PK. Surrogate key.';
EXEC dbo.SetDesc N'LOCATION', N'LocationName', N'Business key. Name of the rental point.';
EXEC dbo.SetDesc N'LOCATION', N'City',         N'City where the rental point is located.';
EXEC dbo.SetDesc N'LOCATION', N'District',     N'District of the city where the rental point is located.';
EXEC dbo.SetDesc N'LOCATION', N'Street',       N'Street and number of the rental point.';
EXEC dbo.SetDesc N'LOCATION', N'Status',       N'Status of the rental point: open, closed.';

-- ===================== EMPLOYEE =====================
EXEC dbo.SetDesc N'EMPLOYEE', NULL, N'Dimension table (SCD2). One tuple describes one employee working in the specified rental point. Contains the special tuple "not rented".';
EXEC dbo.SetDesc N'EMPLOYEE', N'Id_Employee',    N'PK. Surrogate key.';
EXEC dbo.SetDesc N'EMPLOYEE', N'Id_Location',    N'FK to LOCATION. Rental point the employee works in (NULL for "not rented").';
EXEC dbo.SetDesc N'EMPLOYEE', N'EmployeeNo',     N'Business key. Employee identifier (0 for "not rented").';
EXEC dbo.SetDesc N'EMPLOYEE', N'Name',           N'Name of the employee.';
EXEC dbo.SetDesc N'EMPLOYEE', N'Surname',        N'Surname of the employee.';
EXEC dbo.SetDesc N'EMPLOYEE', N'NameAndSurname', N'Name and surname.';
EXEC dbo.SetDesc N'EMPLOYEE', N'IsCurrent',      N'1 if information is current, otherwise 0 (SCD2).';

-- ===================== CLIENT =====================
EXEC dbo.SetDesc N'CLIENT', NULL, N'Dimension table (SCD2). One tuple describes one client in the specified age category. Contains the special tuple "not rented".';
EXEC dbo.SetDesc N'CLIENT', N'Id_Client',      N'PK. Surrogate key.';
EXEC dbo.SetDesc N'CLIENT', N'PID',            N'Business key. Personal Identification Number PESEL (00000000000 for "not rented").';
EXEC dbo.SetDesc N'CLIENT', N'Name',           N'Name of the client.';
EXEC dbo.SetDesc N'CLIENT', N'Surname',        N'Surname of the client.';
EXEC dbo.SetDesc N'CLIENT', N'NameAndSurname', N'Name and surname.';
EXEC dbo.SetDesc N'CLIENT', N'Gender',         N'Gender of the client: male, female.';
EXEC dbo.SetDesc N'CLIENT', N'DateOfBirth',    N'Date of birth (from PESEL).';
EXEC dbo.SetDesc N'CLIENT', N'AgeCategory',    N'Age category: 18-24, 25-34, 35-44, 45-54, 55-64, 65+.';
EXEC dbo.SetDesc N'CLIENT', N'IsCurrent',      N'1 if information is current, otherwise 0 (SCD2).';

-- ===================== DATE =====================
EXEC dbo.SetDesc N'DATE', NULL, N'Dimension table. One tuple describes one day.';
EXEC dbo.SetDesc N'DATE', N'Id_Date',          N'PK. Date identifier.';
EXEC dbo.SetDesc N'DATE', N'Date',             N'Calendar date.';
EXEC dbo.SetDesc N'DATE', N'Year',             N'Year.';
EXEC dbo.SetDesc N'DATE', N'Quarter',          N'Quarter of the year (1-4).';
EXEC dbo.SetDesc N'DATE', N'Month',            N'Month name.';
EXEC dbo.SetDesc N'DATE', N'MonthNo',          N'Month number (1-12).';
EXEC dbo.SetDesc N'DATE', N'DayOfWeek',        N'Day of week name.';
EXEC dbo.SetDesc N'DATE', N'DayOfWeekNo',      N'Day of week number (1 = Monday).';
EXEC dbo.SetDesc N'DATE', N'WorkingDay',       N'day off, working day.';
EXEC dbo.SetDesc N'DATE', N'Season',           N'Season of the year: winter, spring, summer, autumn.';
EXEC dbo.SetDesc N'DATE', N'Vacation',         N'Vacation time characteristics: non-holiday, winter holiday, summer holiday.';
EXEC dbo.SetDesc N'DATE', N'Holiday',          N'Type of public holiday (none if the day is not a holiday).';
EXEC dbo.SetDesc N'DATE', N'BeforeHolidayDay', N'Which holiday is the next day (e.g. tomorrow is Christmas), none otherwise.';

-- ===================== TIME =====================
EXEC dbo.SetDesc N'TIME', NULL, N'Dimension table. One tuple describes one hour (independent of date). Contains the special tuple "no rent".';
EXEC dbo.SetDesc N'TIME', N'Id_Time',   N'PK. Time identifier.';
EXEC dbo.SetDesc N'TIME', N'Hour',      N'Hour (0-23, NULL for "no rent").';
EXEC dbo.SetDesc N'TIME', N'TimeOfDay', N'Time of day: between 0 and 8, 9 and 12, 13 and 15, 16 and 20, 21 and 23, no rent.';

-- ===================== JUNK =====================
EXEC dbo.SetDesc N'JUNK', NULL, N'Junk dimension. All combinations of ReturnStatus, RentalLength, ServiceType, MileageCategory and CarAgeCategory.';
EXEC dbo.SetDesc N'JUNK', N'Id_Junk',         N'PK. Junk identifier.';
EXEC dbo.SetDesc N'JUNK', N'ReturnStatus',    N'Return status of the rent the car is in: on time, late, not rented.';
EXEC dbo.SetDesc N'JUNK', N'RentalLength',    N'Length of the rent the car is in: 1 to 3 days, 4 to 7 days, 8 to 14 days, more than 14 days, not rented.';
EXEC dbo.SetDesc N'JUNK', N'ServiceType',     N'Type of the service the car is in: routine, accident, malfunction, none.';
EXEC dbo.SetDesc N'JUNK', N'ServiceKind',     N'Kind of the service: planned (routine), unexpected (accident, malfunction), none.';
EXEC dbo.SetDesc N'JUNK', N'MileageCategory', N'Mileage of the car on the day: up to 50 000 km, 50 000 to 100 000 km, 100 000 to 200 000 km, over 200 000 km.';
EXEC dbo.SetDesc N'JUNK', N'CarAgeCategory',  N'Age of the car on the day: up to 1 year, 1 to 3 years, 3 to 5 years, over 5 years.';
GO

-- ===================== Check: table and column descriptions =====================
SELECT
    o.name                  AS ObjectName,
    c.name                  AS ColumnName,
    CAST(ep.value AS NVARCHAR(3750)) AS Description
FROM sys.extended_properties AS ep
JOIN sys.objects AS o ON o.object_id = ep.major_id
LEFT JOIN sys.columns AS c ON c.object_id = ep.major_id AND c.column_id = ep.minor_id
WHERE ep.class = 1
  AND ep.name = N'MS_Description'
  AND o.name <> N'FlatTable' AND o.name <> N'FLAT_TABLE'
ORDER BY o.name, ep.minor_id;
GO
