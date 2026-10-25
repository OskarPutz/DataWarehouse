-- Loads one snapshot into RentMaster. Set @snapshot to 'T1' or 'T2' and run the whole file.
USE RentMaster;

DECLARE @snapshot VARCHAR(2) = 'T1';

DECLARE @path VARCHAR(100) = '/generator/output/' + @snapshot + '/';
DECLARE @options VARCHAR(200) = ''' WITH (FIELDTERMINATOR = ''|'', ROWTERMINATOR = ''0x0a'', CODEPAGE = ''RAW'', KEEPIDENTITY, CHECK_CONSTRAINTS, TABLOCK)';

DELETE FROM Rent;
DELETE FROM Service;
DELETE FROM Car;
DELETE FROM Employee;
DELETE FROM Location;

EXEC ('BULK INSERT Location FROM ''' + @path + 'location.bulk' + @options);
EXEC ('BULK INSERT Employee FROM ''' + @path + 'employee.bulk' + @options);
EXEC ('BULK INSERT Car FROM ''' + @path + 'car.bulk' + @options);
EXEC ('BULK INSERT Service FROM ''' + @path + 'service.bulk' + @options);
EXEC ('BULK INSERT Rent FROM ''' + @path + 'rent.bulk' + @options);

SELECT 'Location' AS table_name, COUNT(*) AS row_count FROM Location
UNION ALL SELECT 'Employee', COUNT(*) FROM Employee
UNION ALL SELECT 'Car', COUNT(*) FROM Car
UNION ALL SELECT 'Service', COUNT(*) FROM Service
UNION ALL SELECT 'Rent', COUNT(*) FROM Rent;
