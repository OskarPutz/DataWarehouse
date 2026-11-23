-- Compared with without_partitions, this version adds dbo.CAR_DAY.[Date] (DATE) and partitions the table on PS_CAR_DAY_Date ([Date]).
-- SigmaPol Data Warehouse - relational design (MS SQL Server)
-- Primary keys, foreign keys and indexes are created by the 04_ scripts.
IF DB_ID(N'SigmaPolDW') IS NULL
    CREATE DATABASE SigmaPolDW COLLATE Polish_CI_AS;
GO

USE SigmaPolDW;
GO

-- ===================== Dimension tables =====================

CREATE TABLE dbo.LOCATION (
    Id_Location   INT IDENTITY(1,1) NOT NULL,
    LocationName  VARCHAR(40)       NOT NULL,
    City          VARCHAR(20)       NOT NULL,
    District      VARCHAR(20)       NOT NULL,
    Street        VARCHAR(30)       NOT NULL,
    [Status]      VARCHAR(10)       NOT NULL,
    CONSTRAINT CK_LOCATION_Status CHECK ([Status] IN ('open','closed'))
);
GO

CREATE TABLE dbo.CAR (
    Id_Car          INT IDENTITY(1,1) NOT NULL,
    Id_Location     INT               NOT NULL,
    LicencePlate    VARCHAR(10)       NOT NULL,
    Brand           VARCHAR(20)       NOT NULL,
    Model           VARCHAR(20)       NOT NULL,
    [Type]          VARCHAR(10)       NOT NULL,
    FuelType        VARCHAR(10)       NOT NULL,
    Color           VARCHAR(10)       NOT NULL,
    ProductionYear  SMALLINT          NOT NULL,
    PriceCategory   VARCHAR(15)       NOT NULL,
    IsCurrent       BIT               NOT NULL CONSTRAINT DF_CAR_IsCurrent DEFAULT 1,
    CONSTRAINT CK_CAR_Type CHECK ([Type] IN ('suv','van','combi','sedan','coupe','sport')),
    CONSTRAINT CK_CAR_FuelType CHECK (FuelType IN ('petrol','diesel','LPG','electric','hybrid')),
    CONSTRAINT CK_CAR_ProductionYear CHECK (ProductionYear BETWEEN 1900 AND 9999),
    CONSTRAINT CK_CAR_PriceCategory CHECK (PriceCategory IN ('economy','standard','premium','luxury'))
);
GO

-- Id_Location is NULL only for the special tuple "not rented".
CREATE TABLE dbo.EMPLOYEE (
    Id_Employee     INT IDENTITY(1,1) NOT NULL,
    Id_Location     INT               NULL,
    EmployeeNo      INT               NOT NULL,
    Name            VARCHAR(20)       NOT NULL,
    Surname         VARCHAR(30)       NOT NULL,
    NameAndSurname  VARCHAR(50)       NOT NULL,
    IsCurrent       BIT               NOT NULL CONSTRAINT DF_EMPLOYEE_IsCurrent DEFAULT 1
);
GO

-- 'not rented' values and NULL DateOfBirth are used only by the special tuple "not rented".
CREATE TABLE dbo.CLIENT (
    Id_Client       INT IDENTITY(1,1) NOT NULL,
    PID             CHAR(11)          NOT NULL,
    Name            VARCHAR(20)       NOT NULL,
    Surname         VARCHAR(30)       NOT NULL,
    NameAndSurname  VARCHAR(50)       NOT NULL,
    Gender          VARCHAR(10)       NOT NULL,
    DateOfBirth     DATE              NULL,
    AgeCategory     VARCHAR(10)       NOT NULL,
    IsCurrent       BIT               NOT NULL CONSTRAINT DF_CLIENT_IsCurrent DEFAULT 1,
    CONSTRAINT CK_CLIENT_PID CHECK (PID NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_CLIENT_Gender CHECK (Gender IN ('male','female','not rented')),
    CONSTRAINT CK_CLIENT_AgeCategory CHECK (AgeCategory IN ('18-24','25-34','35-44','45-54','55-64','65+','not rented'))
);
GO

CREATE TABLE dbo.[DATE] (
    Id_Date          INT IDENTITY(1,1) NOT NULL,
    [Date]           DATE              NOT NULL,
    [Year]           SMALLINT          NOT NULL,
    [Quarter]        TINYINT           NOT NULL,
    [Month]          VARCHAR(10)       NOT NULL,
    MonthNo          TINYINT           NOT NULL,
    DayOfWeek        VARCHAR(10)       NOT NULL,
    DayOfWeekNo      TINYINT           NOT NULL,
    WorkingDay       VARCHAR(15)       NOT NULL,
    Season           VARCHAR(10)       NOT NULL,
    Vacation         VARCHAR(20)       NOT NULL,
    Holiday          VARCHAR(50)       NOT NULL,
    BeforeHolidayDay VARCHAR(62)       NOT NULL,
    CONSTRAINT CK_DATE_Year CHECK ([Year] BETWEEN 1000 AND 9999),
    CONSTRAINT CK_DATE_Quarter CHECK ([Quarter] BETWEEN 1 AND 4),
    CONSTRAINT CK_DATE_Month CHECK ([Month] IN ('January','February','March','April','May','June',
                                                'July','August','September','October','November','December')),
    CONSTRAINT CK_DATE_MonthNo CHECK (MonthNo BETWEEN 1 AND 12),
    CONSTRAINT CK_DATE_DayOfWeek CHECK (DayOfWeek IN ('Monday','Tuesday','Wednesday','Thursday',
                                                      'Friday','Saturday','Sunday')),
    CONSTRAINT CK_DATE_DayOfWeekNo CHECK (DayOfWeekNo BETWEEN 1 AND 7),
    CONSTRAINT CK_DATE_WorkingDay CHECK (WorkingDay IN ('day off','working day')),
    CONSTRAINT CK_DATE_Season CHECK (Season IN ('winter','spring','summer','autumn')),
    CONSTRAINT CK_DATE_Vacation CHECK (Vacation IN ('non-holiday','winter holiday','summer holiday'))
);
GO

-- Hour is NULL only for the special tuple "no rent".
CREATE TABLE dbo.[TIME] (
    Id_Time    INT IDENTITY(1,1) NOT NULL,
    [Hour]     TINYINT           NULL,
    TimeOfDay  VARCHAR(20)       NOT NULL,
    CONSTRAINT CK_TIME_Hour CHECK ([Hour] BETWEEN 0 AND 23),
    CONSTRAINT CK_TIME_TimeOfDay CHECK (TimeOfDay IN ('between 0 and 8','between 9 and 12','between 13 and 15',
                                                      'between 16 and 20','between 21 and 23','no rent'))
);
GO

CREATE TABLE dbo.JUNK (
    Id_Junk          INT IDENTITY(1,1) NOT NULL,
    ReturnStatus     VARCHAR(10)       NOT NULL,
    RentalLength     VARCHAR(20)       NOT NULL,
    ServiceType      VARCHAR(15)       NOT NULL,
    ServiceKind      VARCHAR(15)       NOT NULL,
    MileageCategory  VARCHAR(25)       NOT NULL,
    CarAgeCategory   VARCHAR(20)       NOT NULL,
    CONSTRAINT CK_JUNK_ReturnStatus CHECK (ReturnStatus IN ('on time','late','not rented')),
    CONSTRAINT CK_JUNK_RentalLength CHECK (RentalLength IN ('1 to 3 days','4 to 7 days','8 to 14 days',
                                                            'more than 14 days','not rented')),
    CONSTRAINT CK_JUNK_ServiceType CHECK (ServiceType IN ('routine','accident','malfunction','none')),
    CONSTRAINT CK_JUNK_ServiceKind CHECK (ServiceKind IN ('planned','unexpected','none')),
    CONSTRAINT CK_JUNK_MileageCategory CHECK (MileageCategory IN ('up to 50 000 km','50 000 to 100 000 km',
                                                                  '100 000 to 200 000 km','over 200 000 km')),
    CONSTRAINT CK_JUNK_CarAgeCategory CHECK (CarAgeCategory IN ('up to 1 year','1 to 3 years','3 to 5 years','over 5 years'))
);
GO

-- ===================== Fact table =====================

CREATE TABLE dbo.CAR_DAY (
    Id_Date                INT            NOT NULL,
    [Date]                 DATE           NOT NULL,
    Id_Car                 INT            NOT NULL,
    Id_Employee            INT            NOT NULL,
    Id_Client              INT            NOT NULL,
    Id_IssueTime           INT            NOT NULL,
    Id_Junk                INT            NOT NULL,
    RentNo                 INT            NULL,
    ServiceNo              INT            NULL,
    RentedDay              TINYINT        NOT NULL,
    ServiceDay             TINYINT        NOT NULL,
    AvailableDay           TINYINT        NOT NULL,
    IdleDay                TINYINT        NOT NULL,
    Mileage                INT            NOT NULL,
    KmDriven               DECIMAL(8,2)   NOT NULL,
    RentStarted            TINYINT        NOT NULL,
    RentCost               MONEY          NOT NULL,
    RentalDays             SMALLINT       NOT NULL,
    DelayDays              SMALLINT       NOT NULL,
    ServiceStarted         TINYINT        NOT NULL,
    ServiceCost            MONEY          NOT NULL,
    KmSinceLastService     INT            NOT NULL,
    SurveyAnswered         TINYINT        NOT NULL,
    CarConditionRating     TINYINT        NOT NULL,
    IssuesReported         TINYINT        NOT NULL,
    LikelihoodToRentAgain  TINYINT        NOT NULL,
    CONSTRAINT CK_CAR_DAY_Flags CHECK (RentedDay IN (0,1) AND ServiceDay IN (0,1) AND RentStarted IN (0,1)
                                       AND ServiceStarted IN (0,1) AND SurveyAnswered IN (0,1) AND IssuesReported IN (0,1)),
    CONSTRAINT CK_CAR_DAY_AvailableDay CHECK (AvailableDay = 1 - ServiceDay),
    CONSTRAINT CK_CAR_DAY_IdleDay CHECK (IdleDay = AvailableDay - RentedDay),
    CONSTRAINT CK_CAR_DAY_Mileage CHECK (Mileage >= 0 AND KmDriven >= 0 AND KmSinceLastService >= 0),
    CONSTRAINT CK_CAR_DAY_Costs CHECK (RentCost >= 0 AND ServiceCost >= 0),
    CONSTRAINT CK_CAR_DAY_Days CHECK (RentalDays >= 0 AND DelayDays >= 0),
    CONSTRAINT CK_CAR_DAY_Survey CHECK (CarConditionRating BETWEEN 0 AND 5 AND LikelihoodToRentAgain BETWEEN 0 AND 5)
) ON PS_CAR_DAY_Date ([Date]);
GO
