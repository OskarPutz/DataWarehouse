USE SigmaPolDW;
GO

-- ===================== Dimension primary keys =====================

ALTER TABLE dbo.LOCATION ADD CONSTRAINT PK_LOCATION PRIMARY KEY (Id_Location);
ALTER TABLE dbo.CAR      ADD CONSTRAINT PK_CAR      PRIMARY KEY (Id_Car);
ALTER TABLE dbo.EMPLOYEE ADD CONSTRAINT PK_EMPLOYEE PRIMARY KEY (Id_Employee);
ALTER TABLE dbo.CLIENT   ADD CONSTRAINT PK_CLIENT   PRIMARY KEY (Id_Client);
ALTER TABLE dbo.[DATE]   ADD CONSTRAINT PK_DATE     PRIMARY KEY (Id_Date);
ALTER TABLE dbo.[TIME]   ADD CONSTRAINT PK_TIME     PRIMARY KEY (Id_Time);
ALTER TABLE dbo.JUNK     ADD CONSTRAINT PK_JUNK     PRIMARY KEY (Id_Junk);
GO

-- ===================== Foreign keys (snowflake: CAR and EMPLOYEE -> LOCATION) =====================

ALTER TABLE dbo.CAR      ADD CONSTRAINT FK_CAR_LOCATION      FOREIGN KEY (Id_Location) REFERENCES dbo.LOCATION (Id_Location);
ALTER TABLE dbo.EMPLOYEE ADD CONSTRAINT FK_EMPLOYEE_LOCATION FOREIGN KEY (Id_Location) REFERENCES dbo.LOCATION (Id_Location);
GO

-- ===================== Business key indexes =====================

CREATE UNIQUE NONCLUSTERED INDEX UX_LOCATION_LocationName ON dbo.LOCATION (LocationName);
CREATE UNIQUE NONCLUSTERED INDEX UX_DATE_Date ON dbo.[DATE] ([Date]);
-- One NULL is allowed: the special tuple "no rent".
CREATE UNIQUE NONCLUSTERED INDEX UX_TIME_Hour ON dbo.[TIME] ([Hour]);
CREATE UNIQUE NONCLUSTERED INDEX UX_JUNK_All ON dbo.JUNK (ReturnStatus, RentalLength, ServiceType, MileageCategory, CarAgeCategory);

-- SCD2 tables: business key repeats across versions, so indexes are not unique.
CREATE NONCLUSTERED INDEX IX_CAR_LicencePlate ON dbo.CAR (LicencePlate);
CREATE NONCLUSTERED INDEX IX_EMPLOYEE_EmployeeNo ON dbo.EMPLOYEE (EmployeeNo);
CREATE NONCLUSTERED INDEX IX_CLIENT_PID ON dbo.CLIENT (PID);
GO

-- ===================== Foreign key indexes =====================

CREATE NONCLUSTERED INDEX IX_CAR_Id_Location ON dbo.CAR (Id_Location);
CREATE NONCLUSTERED INDEX IX_EMPLOYEE_Id_Location ON dbo.EMPLOYEE (Id_Location);
GO

-- ===================== Disable CHECK and foreign key constraints (e.g. before loading many new tuples) =====================
-- Business key indexes stay enabled: the ETL uses them to find the current version of a car, employee or client (SCD2).
-- Small dimensions can also be loaded with all constraints and indexes enabled.

ALTER TABLE dbo.LOCATION NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.CAR      NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.EMPLOYEE NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.CLIENT   NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[DATE]   NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TIME]   NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.JUNK     NOCHECK CONSTRAINT ALL;
GO

-- ===================== Re-enable CHECK and foreign key constraints =====================

ALTER TABLE dbo.LOCATION WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.CAR      WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.EMPLOYEE WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.CLIENT   WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[DATE]   WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TIME]   WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.JUNK     WITH CHECK CHECK CONSTRAINT ALL;
GO
