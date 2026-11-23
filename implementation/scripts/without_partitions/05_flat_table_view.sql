USE SigmaPolDW;
GO

CREATE OR ALTER VIEW dbo.FlatTable
AS
SELECT
    -- Fact keys (Id_Date + Id_Car identify one row, used as the Cube primary key)
    f.Id_Date,
    f.Id_Car,
    f.RentNo,
    f.ServiceNo,

    -- Fact
    f.RentedDay,
    f.ServiceDay,
    f.AvailableDay,
    f.IdleDay,
    f.Mileage,
    f.KmDriven,
    f.RentStarted,
    f.RentCost,
    f.RentalDays,
    f.DelayDays,
    f.ServiceStarted,
    f.ServiceCost,
    f.KmSinceLastService,
    f.SurveyAnswered,
    f.CarConditionRating,
    f.IssuesReported,
    f.LikelihoodToRentAgain,

    -- New columns of the semantic layer
    ms.MonthStartMileage,
    CASE WHEN f.ServiceStarted = 1 THEN f.Mileage ELSE 0 END                          AS ServiceMileage,
    CASE WHEN f.RentStarted = 1 AND f.DelayDays > 0 THEN 1 ELSE 0 END                AS LateRent,
    CASE WHEN f.ServiceStarted = 1 AND j.ServiceKind = 'unexpected' THEN 1 ELSE 0 END AS UnexpectedService,

    -- Car
    c.LicencePlate,
    c.Brand,
    c.Model,
    c.[Type],
    c.FuelType,
    c.Color,
    c.ProductionYear,
    c.PriceCategory,

    -- Location of the car
    cl.LocationName                                    AS CarLocationName,
    cl.City                                            AS CarCity,
    cl.District                                        AS CarDistrict,
    cl.Street                                          AS CarStreet,
    cl.[Status]                                        AS CarLocationStatus,

    -- Employee and their location ("not rented" has no location)
    e.EmployeeNo,
    e.NameAndSurname                                   AS EmployeeNameAndSurname,
    ISNULL(el.LocationName, 'not rented')              AS EmployeeLocationName,
    ISNULL(el.City, 'not rented')                      AS EmployeeCity,

    -- Client
    cli.PID,
    cli.NameAndSurname                                 AS ClientNameAndSurname,
    cli.Gender,
    cli.AgeCategory,
    CASE
        WHEN cli.AgeCategory = 'not rented' THEN 'not rented'
        WHEN cli.AgeCategory = '18-24'      THEN 'young driver'
        WHEN cli.AgeCategory = '65+'        THEN 'senior driver'
        ELSE 'standard driver'
    END                                                AS ClientSegment,

    -- Date
    d.[Year],
    d.[Quarter],
    d.[Month],
    d.MonthNo,
    d.[Date],
    d.DayOfWeek,
    d.DayOfWeekNo,
    d.WorkingDay,
    d.Season,
    d.Vacation,
    d.Holiday,
    d.BeforeHolidayDay,
    CASE
        WHEN d.Holiday <> 'none'          THEN 'public holiday'
        WHEN d.BeforeHolidayDay <> 'none' THEN 'before holiday'
        WHEN d.WorkingDay = 'day off'     THEN 'weekend'
        WHEN d.Vacation = 'summer holiday' THEN 'summer holiday'
        WHEN d.Vacation = 'winter holiday' THEN 'winter holiday'
        ELSE 'regular day'
    END                                                AS PeriodType,

    -- Issue time
    t.TimeOfDay,
    t.[Hour],

    -- Junk
    j.ReturnStatus,
    j.RentalLength,
    j.ServiceType,
    j.ServiceKind,
    j.MileageCategory,
    CASE
        WHEN ms.MonthStartMileage < 50000  THEN 'up to 50 000 km'
        WHEN ms.MonthStartMileage < 100000 THEN '50 000 to 100 000 km'
        WHEN ms.MonthStartMileage < 200000 THEN '100 000 to 200 000 km'
        ELSE 'over 200 000 km'
    END                                                AS MonthStartMileageCategory,
    j.CarAgeCategory,
    CASE
        WHEN f.SurveyAnswered = 0          THEN 'no survey'
        WHEN f.CarConditionRating >= 4     THEN 'satisfied'
        WHEN f.CarConditionRating = 3      THEN 'neutral'
        ELSE 'dissatisfied'
    END                                                AS SatisfactionLevel
FROM dbo.CAR_DAY    AS f
JOIN dbo.CAR        AS c   ON c.Id_Car        = f.Id_Car
JOIN dbo.LOCATION   AS cl  ON cl.Id_Location  = c.Id_Location
JOIN dbo.EMPLOYEE   AS e   ON e.Id_Employee   = f.Id_Employee
LEFT JOIN dbo.LOCATION AS el ON el.Id_Location = e.Id_Location
JOIN dbo.CLIENT     AS cli ON cli.Id_Client   = f.Id_Client
JOIN dbo.[DATE]     AS d   ON d.Id_Date       = f.Id_Date
JOIN dbo.[TIME]     AS t   ON t.Id_Time       = f.Id_IssueTime
JOIN dbo.JUNK       AS j   ON j.Id_Junk       = f.Id_Junk
CROSS APPLY (
    -- Mileage of the same car (all SCD2 versions) on the first day of the month it is in the fleet
    SELECT TOP (1) f2.Mileage AS MonthStartMileage
    FROM dbo.CAR_DAY AS f2
    JOIN dbo.CAR     AS c2 ON c2.Id_Car  = f2.Id_Car
    JOIN dbo.[DATE]  AS d2 ON d2.Id_Date = f2.Id_Date
    WHERE c2.LicencePlate = c.LicencePlate
      AND d2.[Year] = d.[Year]
      AND d2.MonthNo = d.MonthNo
    ORDER BY d2.[Date]
) AS ms;
GO

-- ===================== Descriptions (dbo.SetDesc from 02_extended_properties.sql) =====================
EXEC dbo.SetDesc N'FlatTable', NULL, N'Semantic layer view (One Big Table). One row describes the state of one car on one day with denormalized car, location, employee, client, date, time and junk attributes.';

-- Fact
EXEC dbo.SetDesc N'FlatTable', N'Id_Date',               N'Date key of the car day (with Id_Car identifies the row).';
EXEC dbo.SetDesc N'FlatTable', N'Id_Car',                N'Car version key of the car day (with Id_Date identifies the row).';
EXEC dbo.SetDesc N'FlatTable', N'RentNo',                N'Number of the rent the car is in on this day.';
EXEC dbo.SetDesc N'FlatTable', N'ServiceNo',             N'Number of the service the car is in on this day.';
EXEC dbo.SetDesc N'FlatTable', N'RentedDay',             N'1 if the car is rented on this day, otherwise 0.';
EXEC dbo.SetDesc N'FlatTable', N'ServiceDay',            N'1 if the car is in the service on this day, otherwise 0.';
EXEC dbo.SetDesc N'FlatTable', N'AvailableDay',          N'1 if the car is available for rental on this day, otherwise 0.';
EXEC dbo.SetDesc N'FlatTable', N'IdleDay',               N'1 if the car is available but not rented on this day, otherwise 0.';
EXEC dbo.SetDesc N'FlatTable', N'Mileage',               N'Mileage of the car at the beginning of the day in km.';
EXEC dbo.SetDesc N'FlatTable', N'KmDriven',              N'Kilometres driven on this day.';
EXEC dbo.SetDesc N'FlatTable', N'RentStarted',           N'1 if a rent is issued on this day, otherwise 0.';
EXEC dbo.SetDesc N'FlatTable', N'RentCost',              N'Total cost of the rent issued on this day.';
EXEC dbo.SetDesc N'FlatTable', N'RentalDays',            N'Number of days of the rent issued on this day.';
EXEC dbo.SetDesc N'FlatTable', N'DelayDays',             N'Delay of the return of the rent issued on this day in days.';
EXEC dbo.SetDesc N'FlatTable', N'ServiceStarted',        N'1 if a service starts on this day, otherwise 0.';
EXEC dbo.SetDesc N'FlatTable', N'ServiceCost',           N'Total cost of the service starting on this day.';
EXEC dbo.SetDesc N'FlatTable', N'KmSinceLastService',    N'Kilometres since the previous service, for the service starting on this day.';
EXEC dbo.SetDesc N'FlatTable', N'SurveyAnswered',        N'1 if the survey for the rent issued on this day was answered.';
EXEC dbo.SetDesc N'FlatTable', N'CarConditionRating',    N'Rating of the car condition (1-5) for the rent issued on this day.';
EXEC dbo.SetDesc N'FlatTable', N'IssuesReported',        N'1 if mechanical issues were reported for the rent issued on this day.';
EXEC dbo.SetDesc N'FlatTable', N'LikelihoodToRentAgain', N'Likelihood to rent again (1-5) for the rent issued on this day.';

-- New columns
EXEC dbo.SetDesc N'FlatTable', N'MonthStartMileage',     N'Mileage of the car on the first day of the month.';
EXEC dbo.SetDesc N'FlatTable', N'ServiceMileage',        N'Mileage if ServiceStarted = 1, otherwise 0.';
EXEC dbo.SetDesc N'FlatTable', N'LateRent',              N'1 if RentStarted = 1 and DelayDays > 0, otherwise 0.';
EXEC dbo.SetDesc N'FlatTable', N'UnexpectedService',     N'1 if ServiceStarted = 1 and ServiceKind = unexpected, otherwise 0.';

-- Car
EXEC dbo.SetDesc N'FlatTable', N'LicencePlate',          N'Licence plate of the car (business key).';
EXEC dbo.SetDesc N'FlatTable', N'Brand',                 N'Brand of the car.';
EXEC dbo.SetDesc N'FlatTable', N'Model',                 N'Model of the car.';
EXEC dbo.SetDesc N'FlatTable', N'Type',                  N'Type of the car.';
EXEC dbo.SetDesc N'FlatTable', N'FuelType',              N'Fuel type of the car.';
EXEC dbo.SetDesc N'FlatTable', N'Color',                 N'Color of the car.';
EXEC dbo.SetDesc N'FlatTable', N'ProductionYear',        N'Year of the car production.';
EXEC dbo.SetDesc N'FlatTable', N'PriceCategory',         N'Price category: economy, standard, premium, luxury.';
EXEC dbo.SetDesc N'FlatTable', N'CarLocationName',       N'Rental point the car is assigned to.';
EXEC dbo.SetDesc N'FlatTable', N'CarCity',               N'City of the rental point of the car.';
EXEC dbo.SetDesc N'FlatTable', N'CarDistrict',           N'District of the rental point of the car.';
EXEC dbo.SetDesc N'FlatTable', N'CarStreet',             N'Street of the rental point of the car.';
EXEC dbo.SetDesc N'FlatTable', N'CarLocationStatus',     N'Status of the rental point of the car: open, closed.';

-- Employee
EXEC dbo.SetDesc N'FlatTable', N'EmployeeNo',            N'Employee identifier (0 = not rented).';
EXEC dbo.SetDesc N'FlatTable', N'EmployeeNameAndSurname', N'Name and surname of the employee who handled the rent.';
EXEC dbo.SetDesc N'FlatTable', N'EmployeeLocationName',  N'Rental point the employee works in.';
EXEC dbo.SetDesc N'FlatTable', N'EmployeeCity',          N'City of the rental point the employee works in.';

-- Client
EXEC dbo.SetDesc N'FlatTable', N'PID',                   N'Client''s PESEL.';
EXEC dbo.SetDesc N'FlatTable', N'ClientNameAndSurname',  N'Client''s name and surname.';
EXEC dbo.SetDesc N'FlatTable', N'Gender',                N'Client''s gender.';
EXEC dbo.SetDesc N'FlatTable', N'AgeCategory',           N'Client''s age category on the day: 18-24, 25-34, 35-44, 45-54, 55-64, 65+.';
EXEC dbo.SetDesc N'FlatTable', N'ClientSegment',         N'young driver (18-24), standard driver (25-64), senior driver (65+), not rented.';

-- Date
EXEC dbo.SetDesc N'FlatTable', N'Year',                  N'Year.';
EXEC dbo.SetDesc N'FlatTable', N'Quarter',               N'Quarter of the year.';
EXEC dbo.SetDesc N'FlatTable', N'Month',                 N'Month name.';
EXEC dbo.SetDesc N'FlatTable', N'MonthNo',               N'Month number.';
EXEC dbo.SetDesc N'FlatTable', N'Date',                  N'Calendar date.';
EXEC dbo.SetDesc N'FlatTable', N'DayOfWeek',             N'Day of week.';
EXEC dbo.SetDesc N'FlatTable', N'DayOfWeekNo',           N'Day of week number (1 = Monday).';
EXEC dbo.SetDesc N'FlatTable', N'WorkingDay',            N'day off, working day.';
EXEC dbo.SetDesc N'FlatTable', N'Season',                N'winter, spring, summer, autumn.';
EXEC dbo.SetDesc N'FlatTable', N'Vacation',              N'non-holiday, winter holiday, summer holiday.';
EXEC dbo.SetDesc N'FlatTable', N'Holiday',               N'Public holiday on the day (none otherwise).';
EXEC dbo.SetDesc N'FlatTable', N'BeforeHolidayDay',      N'Public holiday on the next day (none otherwise).';
EXEC dbo.SetDesc N'FlatTable', N'PeriodType',            N'public holiday, before holiday, weekend, summer holiday, winter holiday, regular day.';

-- Issue time
EXEC dbo.SetDesc N'FlatTable', N'TimeOfDay',             N'Time of day of the rent issue (no rent if no rent starts).';
EXEC dbo.SetDesc N'FlatTable', N'Hour',                  N'Hour of the rent issue.';

-- Junk
EXEC dbo.SetDesc N'FlatTable', N'ReturnStatus',          N'on time, late, not rented.';
EXEC dbo.SetDesc N'FlatTable', N'RentalLength',          N'1 to 3 days, 4 to 7 days, 8 to 14 days, more than 14 days, not rented.';
EXEC dbo.SetDesc N'FlatTable', N'ServiceType',           N'routine, accident, malfunction, none.';
EXEC dbo.SetDesc N'FlatTable', N'ServiceKind',           N'planned, unexpected, none.';
EXEC dbo.SetDesc N'FlatTable', N'MileageCategory',       N'Mileage of the car on the day.';
EXEC dbo.SetDesc N'FlatTable', N'MonthStartMileageCategory', N'Mileage of the car on the first day of the month.';
EXEC dbo.SetDesc N'FlatTable', N'CarAgeCategory',        N'Age of the car on the day.';
EXEC dbo.SetDesc N'FlatTable', N'SatisfactionLevel',     N'satisfied (4-5), neutral (3), dissatisfied (1-2), no survey.';
GO

-- ===================== Test query: first 20 rows of the flat table =====================

SELECT TOP (20) * FROM dbo.FlatTable ORDER BY LicencePlate, [Date];
GO

SELECT COUNT(*) AS FlatRows,
       (SELECT COUNT(*) FROM dbo.CAR_DAY) AS FactRows
FROM dbo.FlatTable;
GO
