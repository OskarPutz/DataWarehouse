/*
    RentMaster — relational source for the SigmaPol Rental "Rent" process.

    Names follow Requirements specification for the Rent business process.
    Clients are not stored here. Rent.client_PESEL is the business key shared
    with the CEO Excel sheet (schemas/ceo_excel/clients.xlsx, column PESEL).

    SQL Server has no YEAR type, so car_year is SMALLINT (YYYY).
    Amounts are PLN, stored as DECIMAL(12,2). The specification says DECIMAL.
    The database collation is Polish_CI_AS so VARCHAR can hold Polish letters.
*/

IF DB_ID(N'RentMaster') IS NULL
BEGIN
    CREATE DATABASE RentMaster COLLATE Polish_CI_AS;
END
GO

USE RentMaster;
GO

IF OBJECT_ID(N'dbo.Location', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Location (
        location_id INT IDENTITY(1, 1) NOT NULL,
        City        VARCHAR(255)       NOT NULL,
        Street      VARCHAR(255)       NOT NULL,
        [Name]      VARCHAR(255)       NOT NULL,
        CONSTRAINT PK_Location PRIMARY KEY CLUSTERED (location_id)
    );
END
GO

IF OBJECT_ID(N'dbo.Employee', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Employee (
        employee_id INT IDENTITY(1, 1) NOT NULL,
        [Name]      VARCHAR(255)       NOT NULL,
        Surname     VARCHAR(255)       NOT NULL,
        location_id INT                NOT NULL,
        CONSTRAINT PK_Employee PRIMARY KEY CLUSTERED (employee_id),
        CONSTRAINT FK_Employee_Location
            FOREIGN KEY (location_id) REFERENCES dbo.Location (location_id)
    );

    CREATE INDEX IX_Employee_location_id ON dbo.Employee (location_id);
END
GO

IF OBJECT_ID(N'dbo.Car', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Car (
        licence_plate   VARCHAR(255)  NOT NULL,
        location_id     INT           NOT NULL,
        Brand           VARCHAR(255)  NOT NULL,
        Model           VARCHAR(255)  NOT NULL,
        Color           VARCHAR(255)  NOT NULL,
        Mileage_current INT           NOT NULL,
        Price_per_day   DECIMAL(12, 2) NOT NULL,
        car_year        SMALLINT      NOT NULL,
        fuel_type       VARCHAR(255)  NOT NULL,
        [type]          VARCHAR(255)  NOT NULL,
        CONSTRAINT PK_Car PRIMARY KEY CLUSTERED (licence_plate),
        CONSTRAINT FK_Car_Location
            FOREIGN KEY (location_id) REFERENCES dbo.Location (location_id),
        CONSTRAINT CK_Car_Mileage_current CHECK (Mileage_current >= 0),
        CONSTRAINT CK_Car_Price_per_day CHECK (Price_per_day >= 0),
        CONSTRAINT CK_Car_car_year CHECK (car_year BETWEEN 1950 AND 2100),
        CONSTRAINT CK_Car_fuel_type CHECK (
            fuel_type IN (N'petrol', N'diesel', N'LPG', N'electric', N'hybrid')
        ),
        CONSTRAINT CK_Car_type CHECK (
            [type] IN (N'suv', N'van', N'combi', N'sedan', N'coupe', N'sport')
        )
    );

    CREATE INDEX IX_Car_location_id ON dbo.Car (location_id);
END
GO

IF OBJECT_ID(N'dbo.Rent', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Rent (
        rent_id                INT IDENTITY(1, 1) NOT NULL,
        client_PESEL           VARCHAR(11)        NOT NULL,
        car_licence_plate      VARCHAR(255)       NOT NULL,
        employee_id            INT                NOT NULL,
        date_issued            DATETIME           NOT NULL,
        date_returned_planned  DATETIME           NOT NULL,
        date_returned_actual   DATETIME           NULL,
        cost                   DECIMAL(12, 2)     NOT NULL,
        mileage_before         INT                NOT NULL,
        mileage_after          INT                NULL,
        CONSTRAINT PK_Rent PRIMARY KEY CLUSTERED (rent_id),
        CONSTRAINT FK_Rent_Car
            FOREIGN KEY (car_licence_plate) REFERENCES dbo.Car (licence_plate),
        CONSTRAINT FK_Rent_Employee
            FOREIGN KEY (employee_id) REFERENCES dbo.Employee (employee_id),
        CONSTRAINT CK_Rent_client_PESEL CHECK (
            client_PESEL LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        ),
        CONSTRAINT CK_Rent_cost CHECK (cost >= 0),
        CONSTRAINT CK_Rent_mileage_before CHECK (mileage_before >= 0),
        CONSTRAINT CK_Rent_mileage_after CHECK (
            mileage_after IS NULL OR mileage_after >= mileage_before
        ),
        CONSTRAINT CK_Rent_planned_return CHECK (date_returned_planned >= date_issued),
        CONSTRAINT CK_Rent_actual_return CHECK (
            date_returned_actual IS NULL OR date_returned_actual >= date_issued
        )
    );

    CREATE INDEX IX_Rent_client_PESEL ON dbo.Rent (client_PESEL);
    CREATE INDEX IX_Rent_car_licence_plate ON dbo.Rent (car_licence_plate);
    CREATE INDEX IX_Rent_employee_id ON dbo.Rent (employee_id);
    CREATE INDEX IX_Rent_date_issued ON dbo.Rent (date_issued);
END
GO

IF OBJECT_ID(N'dbo.Service', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Service (
        service_id        INT IDENTITY(1, 1) NOT NULL,
        car_licence_plate VARCHAR(255)       NOT NULL,
        start_date        DATE               NOT NULL,
        end_date          DATE               NOT NULL,
        mileage           INT                NOT NULL,
        cost              DECIMAL(12, 2)     NOT NULL,
        [type]            VARCHAR(255)       NOT NULL,
        description       VARCHAR(255)       NULL,
        CONSTRAINT PK_Service PRIMARY KEY CLUSTERED (service_id),
        CONSTRAINT FK_Service_Car
            FOREIGN KEY (car_licence_plate) REFERENCES dbo.Car (licence_plate),
        CONSTRAINT CK_Service_dates CHECK (end_date >= start_date),
        CONSTRAINT CK_Service_mileage CHECK (mileage >= 0),
        CONSTRAINT CK_Service_cost CHECK (cost >= 0),
        CONSTRAINT CK_Service_type CHECK (
            [type] IN (N'routine', N'accident', N'malfunction')
        )
    );

    CREATE INDEX IX_Service_car_licence_plate ON dbo.Service (car_licence_plate);
    CREATE INDEX IX_Service_start_date ON dbo.Service (start_date);
END
GO
