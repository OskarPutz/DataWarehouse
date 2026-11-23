USE SigmaPolDW;
GO

-- ===================== Flat table =====================

DROP TABLE IF EXISTS dbo.FLAT_TABLE;
GO

CREATE TABLE dbo.FLAT_TABLE (
    Id_Date                   INT NOT NULL,
    Id_Car                    INT NOT NULL,
    RentNo                    INT NULL,
    ServiceNo                 INT NULL,
    RentedDay                 TINYINT NOT NULL,
    ServiceDay                TINYINT NOT NULL,
    AvailableDay              TINYINT NOT NULL,
    IdleDay                   TINYINT NOT NULL,
    Mileage                   INT NOT NULL,
    KmDriven                  DECIMAL(8,2) NOT NULL,
    RentStarted               TINYINT NOT NULL,
    RentCost                  MONEY NOT NULL,
    RentalDays                SMALLINT NOT NULL,
    DelayDays                 SMALLINT NOT NULL,
    ServiceStarted            TINYINT NOT NULL,
    ServiceCost               MONEY NOT NULL,
    KmSinceLastService        INT NOT NULL,
    SurveyAnswered            TINYINT NOT NULL,
    CarConditionRating        TINYINT NOT NULL,
    IssuesReported            TINYINT NOT NULL,
    LikelihoodToRentAgain     TINYINT NOT NULL,
    MonthStartMileage         INT NOT NULL,
    ServiceMileage            INT NOT NULL,
    LateRent                  TINYINT NOT NULL,
    UnexpectedService         TINYINT NOT NULL,
    LicencePlate              VARCHAR(10) NOT NULL,
    Brand                     VARCHAR(20) NOT NULL,
    Model                     VARCHAR(20) NOT NULL,
    [Type]                    VARCHAR(10) NOT NULL,
    FuelType                  VARCHAR(10) NOT NULL,
    Color                     VARCHAR(10) NOT NULL,
    ProductionYear            SMALLINT NOT NULL,
    PriceCategory             VARCHAR(15) NOT NULL,
    CarLocationName           VARCHAR(40) NOT NULL,
    CarCity                   VARCHAR(20) NOT NULL,
    CarDistrict               VARCHAR(20) NOT NULL,
    CarStreet                 VARCHAR(30) NOT NULL,
    CarLocationStatus         VARCHAR(10) NOT NULL,
    EmployeeNo                INT NOT NULL,
    EmployeeNameAndSurname    VARCHAR(50) NOT NULL,
    EmployeeLocationName      VARCHAR(40) NOT NULL,
    EmployeeCity              VARCHAR(20) NOT NULL,
    PID                       CHAR(11) NOT NULL,
    ClientNameAndSurname      VARCHAR(50) NOT NULL,
    Gender                    VARCHAR(10) NOT NULL,
    AgeCategory               VARCHAR(10) NOT NULL,
    ClientSegment             VARCHAR(15) NOT NULL,
    [Year]                    SMALLINT NOT NULL,
    [Quarter]                 TINYINT NOT NULL,
    [Month]                   VARCHAR(10) NOT NULL,
    MonthNo                   TINYINT NOT NULL,
    [Date]                    DATE NOT NULL,
    DayOfWeek                 VARCHAR(10) NOT NULL,
    DayOfWeekNo               TINYINT NOT NULL,
    WorkingDay                VARCHAR(15) NOT NULL,
    Season                    VARCHAR(10) NOT NULL,
    Vacation                  VARCHAR(20) NOT NULL,
    Holiday                   VARCHAR(50) NOT NULL,
    BeforeHolidayDay          VARCHAR(62) NOT NULL,
    PeriodType                VARCHAR(15) NOT NULL,
    TimeOfDay                 VARCHAR(20) NOT NULL,
    [Hour]                    TINYINT NULL,
    ReturnStatus              VARCHAR(10) NOT NULL,
    RentalLength              VARCHAR(20) NOT NULL,
    ServiceType               VARCHAR(15) NOT NULL,
    ServiceKind               VARCHAR(15) NOT NULL,
    MileageCategory           VARCHAR(25) NOT NULL,
    MonthStartMileageCategory VARCHAR(25) NOT NULL,
    CarAgeCategory            VARCHAR(20) NOT NULL,
    SatisfactionLevel         VARCHAR(15) NOT NULL
);
GO

-- ===================== Descriptions (dbo.SetDesc from 02_extended_properties.sql; same as dbo.FlatTable) =====================
EXEC dbo.SetDesc N'FLAT_TABLE', NULL, N'Semantic layer table (One Big Table), materialized copy of the FlatTable view. One row describes the state of one car on one day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Id_Date',               N'Date key of the car day (with Id_Car identifies the row).';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Id_Car',                N'Car version key of the car day (with Id_Date identifies the row).';
EXEC dbo.SetDesc N'FLAT_TABLE', N'RentNo',                N'Number of the rent the car is in on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ServiceNo',             N'Number of the service the car is in on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'RentedDay',             N'1 if the car is rented on this day, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ServiceDay',            N'1 if the car is in the service on this day, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'AvailableDay',          N'1 if the car is available for rental on this day, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'IdleDay',               N'1 if the car is available but not rented on this day, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Mileage',               N'Mileage of the car at the beginning of the day in km.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'KmDriven',              N'Kilometres driven on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'RentStarted',           N'1 if a rent is issued on this day, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'RentCost',              N'Total cost of the rent issued on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'RentalDays',            N'Number of days of the rent issued on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'DelayDays',             N'Delay of the return of the rent issued on this day in days.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ServiceStarted',        N'1 if a service starts on this day, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ServiceCost',           N'Total cost of the service starting on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'KmSinceLastService',    N'Kilometres since the previous service, for the service starting on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'SurveyAnswered',        N'1 if the survey for the rent issued on this day was answered.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'CarConditionRating',    N'Rating of the car condition (1-5) for the rent issued on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'IssuesReported',        N'1 if mechanical issues were reported for the rent issued on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'LikelihoodToRentAgain', N'Likelihood to rent again (1-5) for the rent issued on this day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'MonthStartMileage',     N'Mileage of the car on the first day of the month.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ServiceMileage',        N'Mileage if ServiceStarted = 1, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'LateRent',              N'1 if RentStarted = 1 and DelayDays > 0, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'UnexpectedService',     N'1 if ServiceStarted = 1 and ServiceKind = unexpected, otherwise 0.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'LicencePlate',          N'Licence plate of the car (business key).';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Brand',                 N'Brand of the car.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Model',                 N'Model of the car.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Type',                  N'Type of the car.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'FuelType',              N'Fuel type of the car.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Color',                 N'Color of the car.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ProductionYear',        N'Year of the car production.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'PriceCategory',         N'Price category: economy, standard, premium, luxury.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'CarLocationName',       N'Rental point the car is assigned to.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'CarCity',               N'City of the rental point of the car.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'CarDistrict',           N'District of the rental point of the car.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'CarStreet',             N'Street of the rental point of the car.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'CarLocationStatus',     N'Status of the rental point of the car: open, closed.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'EmployeeNo',            N'Employee identifier (0 = not rented).';
EXEC dbo.SetDesc N'FLAT_TABLE', N'EmployeeNameAndSurname', N'Name and surname of the employee who handled the rent.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'EmployeeLocationName',  N'Rental point the employee works in.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'EmployeeCity',          N'City of the rental point the employee works in.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'PID',                   N'Client''s PESEL.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ClientNameAndSurname',  N'Client''s name and surname.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Gender',                N'Client''s gender.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'AgeCategory',           N'Client''s age category on the day: 18-24, 25-34, 35-44, 45-54, 55-64, 65+.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ClientSegment',         N'young driver (18-24), standard driver (25-64), senior driver (65+), not rented.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Year',                  N'Year.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Quarter',               N'Quarter of the year.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Month',                 N'Month name.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'MonthNo',               N'Month number.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Date',                  N'Calendar date.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'DayOfWeek',             N'Day of week.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'DayOfWeekNo',           N'Day of week number (1 = Monday).';
EXEC dbo.SetDesc N'FLAT_TABLE', N'WorkingDay',            N'day off, working day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Season',                N'winter, spring, summer, autumn.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Vacation',              N'non-holiday, winter holiday, summer holiday.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Holiday',               N'Public holiday on the day (none otherwise).';
EXEC dbo.SetDesc N'FLAT_TABLE', N'BeforeHolidayDay',      N'Public holiday on the next day (none otherwise).';
EXEC dbo.SetDesc N'FLAT_TABLE', N'PeriodType',            N'public holiday, before holiday, weekend, summer holiday, winter holiday, regular day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'TimeOfDay',             N'Time of day of the rent issue (no rent if no rent starts).';
EXEC dbo.SetDesc N'FLAT_TABLE', N'Hour',                  N'Hour of the rent issue.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ReturnStatus',          N'on time, late, not rented.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'RentalLength',          N'1 to 3 days, 4 to 7 days, 8 to 14 days, more than 14 days, not rented.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ServiceType',           N'routine, accident, malfunction, none.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'ServiceKind',           N'planned, unexpected, none.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'MileageCategory',       N'Mileage of the car on the day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'MonthStartMileageCategory', N'Mileage of the car on the first day of the month.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'CarAgeCategory',        N'Age of the car on the day.';
EXEC dbo.SetDesc N'FLAT_TABLE', N'SatisfactionLevel',     N'satisfied (4-5), neutral (3), dissatisfied (1-2), no survey.';
GO

-- ===================== Load the flat table from the view year by year =====================

INSERT INTO dbo.FLAT_TABLE (
    Id_Date, Id_Car, RentNo, ServiceNo, RentedDay, ServiceDay,
    AvailableDay, IdleDay, Mileage, KmDriven, RentStarted, RentCost,
    RentalDays, DelayDays, ServiceStarted, ServiceCost, KmSinceLastService, SurveyAnswered,
    CarConditionRating, IssuesReported, LikelihoodToRentAgain, MonthStartMileage, ServiceMileage, LateRent,
    UnexpectedService, LicencePlate, Brand, Model, [Type], FuelType,
    Color, ProductionYear, PriceCategory, CarLocationName, CarCity, CarDistrict,
    CarStreet, CarLocationStatus, EmployeeNo, EmployeeNameAndSurname, EmployeeLocationName, EmployeeCity,
    PID, ClientNameAndSurname, Gender, AgeCategory, ClientSegment, [Year],
    [Quarter], [Month], MonthNo, [Date], DayOfWeek, DayOfWeekNo,
    WorkingDay, Season, Vacation, Holiday, BeforeHolidayDay, PeriodType,
    TimeOfDay, [Hour], ReturnStatus, RentalLength, ServiceType, ServiceKind,
    MileageCategory, MonthStartMileageCategory, CarAgeCategory, SatisfactionLevel
)
SELECT
    Id_Date, Id_Car, RentNo, ServiceNo, RentedDay, ServiceDay,
    AvailableDay, IdleDay, Mileage, KmDriven, RentStarted, RentCost,
    RentalDays, DelayDays, ServiceStarted, ServiceCost, KmSinceLastService, SurveyAnswered,
    CarConditionRating, IssuesReported, LikelihoodToRentAgain, MonthStartMileage, ServiceMileage, LateRent,
    UnexpectedService, LicencePlate, Brand, Model, [Type], FuelType,
    Color, ProductionYear, PriceCategory, CarLocationName, CarCity, CarDistrict,
    CarStreet, CarLocationStatus, EmployeeNo, EmployeeNameAndSurname, EmployeeLocationName, EmployeeCity,
    PID, ClientNameAndSurname, Gender, AgeCategory, ClientSegment, [Year],
    [Quarter], [Month], MonthNo, [Date], DayOfWeek, DayOfWeekNo,
    WorkingDay, Season, Vacation, Holiday, BeforeHolidayDay, PeriodType,
    TimeOfDay, [Hour], ReturnStatus, RentalLength, ServiceType, ServiceKind,
    MileageCategory, MonthStartMileageCategory, CarAgeCategory, SatisfactionLevel
FROM dbo.FlatTable
WHERE [Date] BETWEEN '2025-01-01' AND '2025-12-31';
GO

CREATE CLUSTERED COLUMNSTORE INDEX CCI_FLAT_TABLE
    ON dbo.FLAT_TABLE
    ORDER ([Date]);
GO

INSERT INTO dbo.FLAT_TABLE (
    Id_Date, Id_Car, RentNo, ServiceNo, RentedDay, ServiceDay,
    AvailableDay, IdleDay, Mileage, KmDriven, RentStarted, RentCost,
    RentalDays, DelayDays, ServiceStarted, ServiceCost, KmSinceLastService, SurveyAnswered,
    CarConditionRating, IssuesReported, LikelihoodToRentAgain, MonthStartMileage, ServiceMileage, LateRent,
    UnexpectedService, LicencePlate, Brand, Model, [Type], FuelType,
    Color, ProductionYear, PriceCategory, CarLocationName, CarCity, CarDistrict,
    CarStreet, CarLocationStatus, EmployeeNo, EmployeeNameAndSurname, EmployeeLocationName, EmployeeCity,
    PID, ClientNameAndSurname, Gender, AgeCategory, ClientSegment, [Year],
    [Quarter], [Month], MonthNo, [Date], DayOfWeek, DayOfWeekNo,
    WorkingDay, Season, Vacation, Holiday, BeforeHolidayDay, PeriodType,
    TimeOfDay, [Hour], ReturnStatus, RentalLength, ServiceType, ServiceKind,
    MileageCategory, MonthStartMileageCategory, CarAgeCategory, SatisfactionLevel
)
SELECT
    Id_Date, Id_Car, RentNo, ServiceNo, RentedDay, ServiceDay,
    AvailableDay, IdleDay, Mileage, KmDriven, RentStarted, RentCost,
    RentalDays, DelayDays, ServiceStarted, ServiceCost, KmSinceLastService, SurveyAnswered,
    CarConditionRating, IssuesReported, LikelihoodToRentAgain, MonthStartMileage, ServiceMileage, LateRent,
    UnexpectedService, LicencePlate, Brand, Model, [Type], FuelType,
    Color, ProductionYear, PriceCategory, CarLocationName, CarCity, CarDistrict,
    CarStreet, CarLocationStatus, EmployeeNo, EmployeeNameAndSurname, EmployeeLocationName, EmployeeCity,
    PID, ClientNameAndSurname, Gender, AgeCategory, ClientSegment, [Year],
    [Quarter], [Month], MonthNo, [Date], DayOfWeek, DayOfWeekNo,
    WorkingDay, Season, Vacation, Holiday, BeforeHolidayDay, PeriodType,
    TimeOfDay, [Hour], ReturnStatus, RentalLength, ServiceType, ServiceKind,
    MileageCategory, MonthStartMileageCategory, CarAgeCategory, SatisfactionLevel
FROM dbo.FlatTable
WHERE [Date] BETWEEN '2026-01-01' AND '2026-12-31';
GO

-- The increment goes straight into the existing index; REORGANIZE compresses its delta rowgroups without rebuilding the 2025 data.
ALTER INDEX CCI_FLAT_TABLE ON dbo.FLAT_TABLE REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);
GO

-- ===================== Test query: the flat table has the same rows as the fact table =====================

SELECT TOP (20) * FROM dbo.FLAT_TABLE ORDER BY LicencePlate, [Date];
GO

SELECT COUNT(*) AS FlatRows,
       (SELECT COUNT(*) FROM dbo.CAR_DAY) AS FactRows
FROM dbo.FLAT_TABLE;
GO
