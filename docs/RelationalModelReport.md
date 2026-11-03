---
title: "Task 3: SigmaPol Data Warehouse - relational design"
---

**Authors:** Oskar Putz, Łukasz Gajkowski

# 1. Business Process

The data warehouse is designed for the car rental business process, together with the fleet servicing
process, whose data is needed to calculate the idle time and the utilization rate of cars. These processes
are described in the documents *Specification of business processes in SigmaPol Rental network* and
*Requirements specification for Rent business process*.

The data warehouse uses a **constellation schema**: three fact tables (RENT, SERVICE and CAR_STATUS) share
the dimensions CAR, DATE and JUNK-type dimensions. The dimensions CAR and EMPLOYEE are snowflaked with the
dimension LOCATION.

# 2. Relational Database Schema / Tables Specification

## Fact Tables

**RENT (Fact Table)**

One tuple describes one fact of renting one car by one client, from its issuance to its return.

- **Id_IssueDate (Numeric, FK Date):** Rent issue date.
- **Id_IssueTime (Numeric, FK Time):** Rent issue time.
- **Id_PlannedReturnDate (Numeric, FK Date):** Planned return date.
- **Id_ReturnDate (Numeric, FK Date):** Actual return date.
- **Id_ReturnTime (Numeric, FK Time):** Actual return time.
- **Id_Car (Numeric, FK Car):** Rented car.
- **Id_Employee (Numeric, FK Employee):** Employee who handled the rent.
- **Id_Client (Numeric, FK Client):** Client who rented the car.
- **Id_Junk (Numeric, FK Junk_Rent):** Junk attributes of the rent.
- **RentNo (Numeric):** Rent number.
- **Cost (Money):** Total cost of the rent paid by the client.
- **RentalDays (Numeric):** Number of days the car was rented (from issue to actual return).
- **PlannedDays (Numeric):** Number of days the car was planned to be rented.
- **DelayDays (Numeric):** Number of days the car was returned after the planned return date (0 if on time).
- **KmDriven (Numeric):** Number of kilometres driven during the rent.
- **MileageBefore (Numeric):** Mileage of the car before the rent in km.
- **MileageAfter (Numeric):** Mileage of the car after the rent in km.

**SERVICE (Fact Table)**

One tuple describes one fact of servicing one car in a workshop.

- **Id_StartDate (Numeric, FK Date):** Date of the car's arrival in the service.
- **Id_EndDate (Numeric, FK Date):** Date of the car's return from the service.
- **Id_Car (Numeric, FK Car):** Serviced car.
- **Id_Junk (Numeric, FK Junk_Service):** Junk attributes of the service.
- **ServiceNo (Numeric):** Service number.
- **Cost (Money):** Total cost of the service.
- **ServiceDays (Numeric):** Number of days the car was unavailable because of the service.
- **Mileage (Numeric):** Mileage of the car at the moment of the service in km.
- **KmSinceLastService (Numeric):** Number of kilometres driven since the previous service of the car.
- **DaysSinceLastService (Numeric):** Number of days since the previous service of the car.

**CAR_STATUS (Fact Table)**

One tuple describes the status of one car of the fleet on one day (periodic snapshot). The table makes it
possible to calculate the utilization rate and the number of idle days for any period.

- **Id_Date (Numeric, FK Date):** Day described by the tuple.
- **Id_Car (Numeric, FK Car):** Car described by the tuple.
- **Id_Employee (Numeric, FK Employee):** Employee who handled the rent the car is in on this day
  (special tuple "not rented" if the car is not rented).
- **Id_Client (Numeric, FK Client):** Client who rents the car on this day
  (special tuple "not rented" if the car is not rented).
- **Id_Junk (Numeric, FK Junk_CarStatus):** Junk attributes of the car on this day.
- **RentedDay (Numeric):** 1 if the car is rented on this day, otherwise 0.
- **ServiceDay (Numeric):** 1 if the car is in the service on this day, otherwise 0.
- **AvailableDay (Numeric):** 1 if the car is available for rental on this day (not in the service), otherwise 0.
- **IdleDay (Numeric):** 1 if the car is available but not rented on this day, otherwise 0.
- **Mileage (Numeric):** Mileage of the car at the beginning of the day in km.

## Dimension Tables

**CAR (Dimension Table)**

One tuple describes one car of the fleet, assigned to one rental point, within one price category.

- **Id_Car (Numeric, PK):** Surrogate key.
- **Id_Location (Numeric, FK Location):** Rental point the car is assigned to.
- **LicencePlate (Varchar(10), BK):** Business key, licence plate of the car.
- **Brand (Varchar(20)):** Brand of the car.
- **Model (Varchar(20)):** Model of the car.
- **Type (Varchar(10)):** Type of the car. Allowed values: suv, van, combi, sedan, coupe, sport.
- **FuelType (Varchar(10)):** Fuel type of the car. Allowed values: petrol, diesel, LPG, electric, hybrid.
- **Color (Varchar(10)):** Color of the car.
- **ProductionYear (4 digits):** Year of the car production.
- **PriceCategory (Varchar(15)):** Price category of the car based on its daily price. Allowed values:
  economy, standard, premium, luxury.
- **IsCurrent (Boolean):** 1 if information is current, otherwise 0 (SCD2 implementation).

**LOCATION (Dimension Table)**

One tuple describes one rental point.

- **Id_Location (Numeric, PK):** Surrogate key.
- **LocationName (Varchar(40), BK):** Business key, name of the rental point.
- **City (Varchar(20)):** City where the rental point is located.
- **District (Varchar(20)):** District of the city where the rental point is located.
- **Street (Varchar(30)):** Street and number of the rental point.
- **Status (Varchar(10)):** Status of the rental point. Allowed values: open, closed.

**EMPLOYEE (Dimension Table)**

One tuple describes one employee working in the specified rental point.

- **Id_Employee (Numeric, PK):** Surrogate key.
- **Id_Location (Numeric, FK Location):** Rental point the employee works in.
- **EmployeeNo (Numeric, BK):** Business key, employee identifier.
- **Name (Varchar(20)):** Name of the employee.
- **Surname (Varchar(30)):** Surname of the employee.
- **NameAndSurname (Varchar(50)):** Name and surname.
- **IsCurrent (Boolean):** 1 if information is current, otherwise 0 (SCD2 implementation).

The table contains one special tuple "not rented" used by CAR_STATUS for days when the car is not rented.

**CLIENT (Dimension Table)**

One tuple describes one client in the specified age category.

- **Id_Client (Numeric, PK):** Surrogate key.
- **PID (11 digits, BK):** Business key, Personal Identification Number PESEL.
- **Name (Varchar(20)):** Name of the client.
- **Surname (Varchar(30)):** Surname of the client.
- **NameAndSurname (Varchar(50)):** Name and surname.
- **Gender (Varchar(10)):** Gender of the client. Allowed values: male, female.
- **DateOfBirth (Date):** Date of birth.
- **AgeCategory (Varchar(10)):** Age category. Allowed values: 18-24, 25-34, 35-44, 45-54, 55-64, 65+.
- **IsCurrent (Boolean):** 1 if information is current, otherwise 0 (SCD2 implementation).

The table contains one special tuple "not rented" used by CAR_STATUS for days when the car is not rented.

**DATE (Dimension Table)**

One tuple describes one day.

- **Id_Date (Numeric, PK):** Date identifier.
- **Date (Date):** Calendar date.
- **Year (4 digits):** Year.
- **Quarter (Numeric):** Quarter of the year (values from 1 to 4).
- **Month (Varchar(10)):** Month name (January, February, ..., December).
- **MonthNo (Numeric):** Month's numeric value.
- **DayOfWeek (Varchar(10)):** Day of week (Monday, Tuesday, ..., Sunday).
- **DayOfWeekNo (Numeric):** Weekday's numeric value.
- **WorkingDay (Varchar(15)):** Allowed values: day off, working day.
- **Season (Varchar(10)):** Season of the year. Allowed values: winter, spring, summer, autumn.
- **Vacation (Varchar(20)):** Vacation time characteristics. Allowed values: non-holiday, winter holiday,
  summer holiday.
- **Holiday (Varchar(50)):** Type of public holiday. Allowed values: none, New Year, Epiphany, Easter,
  Easter Monday, Labour Day, Constitution Day, Pentecost, Corpus Christi, Assumption Day, All Saints' Day,
  Independence Day, Christmas Eve, Christmas, Second Day of Christmas.
- **BeforeHolidayDay (Varchar(62)):** Allowed values: none, tomorrow is New Year, tomorrow is Easter, etc.

**TIME (Dimension Table)**

One tuple describes one hour (independent of date).

- **Id_Time (Numeric, PK):** Time identifier.
- **Hour (Numeric):** Hour (values from 0 to 23).
- **TimeOfDay (Varchar(20)):** Time of day. Allowed values: between 0 and 8, between 9 and 12,
  between 13 and 15, between 16 and 20, between 21 and 23.

**JUNK_RENT (Dimension Table)**

The tuples correspond to all possible combinations of values for ReturnStatus and RentalLength.

- **Id_Junk (Numeric, PK):** Junk identifier.
- **ReturnStatus (Varchar(10)):** Return status of the rent. Allowed values: on time, late.
- **RentalLength (Varchar(20)):** Length of the rent. Allowed values: 1 to 3 days, 4 to 7 days,
  8 to 14 days, more than 14 days.

**JUNK_SERVICE (Dimension Table)**

The tuples correspond to all possible combinations of values for ServiceType and CarAgeCategory
(ServiceKind results from ServiceType).

- **Id_Junk (Numeric, PK):** Junk identifier.
- **ServiceType (Varchar(15)):** Type of the service. Allowed values: routine, accident, malfunction.
- **ServiceKind (Varchar(15)):** Kind of the service. Allowed values: planned (routine), unexpected
  (accident, malfunction).
- **CarAgeCategory (Varchar(20)):** Age of the car at the moment of the service. Allowed values:
  up to 1 year, 1 to 3 years, 3 to 5 years, over 5 years.

**JUNK_CARSTATUS (Dimension Table)**

The tuples correspond to all possible combinations of values for MileageCategory and CarAgeCategory.

- **Id_Junk (Numeric, PK):** Junk identifier.
- **MileageCategory (Varchar(25)):** Mileage of the car on the day. Allowed values: up to 50 000 km,
  50 000 to 100 000 km, 100 000 to 200 000 km, over 200 000 km.
- **CarAgeCategory (Varchar(20)):** Age of the car on the day. Allowed values: up to 1 year, 1 to 3 years,
  3 to 5 years, over 5 years.

## Hierarchies

Besides the date hierarchy (Year → Quarter → Month → Date) and the time hierarchy (TimeOfDay → Hour), the
data warehouse contains the following hierarchies:

- **Location hierarchy:** City → District → Rental point (LOCATION).
- **Car hierarchy:** Brand → Model → Car (CAR).
- **Organizational hierarchy:** Rental point (LOCATION) → Employee (EMPLOYEE).

# 3. Checking Data Availability in Data Sources (ETL Mapping)

The data sources are the **RentMaster** relational database (tables Rent, Car, Employee, Location and
Service) and the **CEO Excel** file (Sheet 1, information about clients).

**RENT**

- **Id_IssueDate:** Foreign key from dimension table. Based on date_issued stored in Rent table in
  RentMaster source.
- **Id_IssueTime:** Foreign key from dimension table. Based on the hour of date_issued stored in Rent table
  in RentMaster source.
- **Id_PlannedReturnDate:** Foreign key from dimension table. Based on date_returned_planned stored in Rent
  table in RentMaster source.
- **Id_ReturnDate:** Foreign key from dimension table. Based on date_returned_actual stored in Rent table in
  RentMaster source.
- **Id_ReturnTime:** Foreign key from dimension table. Based on the hour of date_returned_actual stored in
  Rent table in RentMaster source.
- **Id_Car:** Foreign key from dimension table. Based on car_licence_plate in Rent table in RentMaster source
  and the version of the car (rental point, price category) valid at date_issued.
- **Id_Employee:** Foreign key from dimension table. Based on employee_id in Rent table in RentMaster source
  and the version of the employee (rental point) valid at date_issued.
- **Id_Client:** Foreign key from dimension table. Based on client_PESEL in Rent table in RentMaster source
  and the age category of the client at date_issued (calculated from the date of birth encoded in PESEL).
- **Id_Junk:** Foreign key from dimension table. Based on date_returned_planned, date_returned_actual and
  date_issued in Rent table in RentMaster source.
- **RentNo:** Taken from rent_id column in Rent table in RentMaster source.
- **Cost:** Taken from cost column in Rent table in RentMaster source.
- **RentalDays:** Calculated as the number of days between date_issued and date_returned_actual in Rent
  table in RentMaster source.
- **PlannedDays:** Calculated as the number of days between date_issued and date_returned_planned in Rent
  table in RentMaster source.
- **DelayDays:** Calculated as the number of days between date_returned_planned and date_returned_actual in
  Rent table in RentMaster source (0 if the car was returned on time).
- **KmDriven:** Calculated as the difference between mileage_after and mileage_before in Rent table in
  RentMaster source.
- **MileageBefore:** Taken from mileage_before column in Rent table in RentMaster source.
- **MileageAfter:** Taken from mileage_after column in Rent table in RentMaster source.

**SERVICE**

- **Id_StartDate:** Foreign key from dimension table. Based on start_date stored in Service table in
  RentMaster source.
- **Id_EndDate:** Foreign key from dimension table. Based on end_date stored in Service table in RentMaster
  source.
- **Id_Car:** Foreign key from dimension table. Based on car_licence_plate in Service table in RentMaster
  source and the version of the car valid at start_date.
- **Id_Junk:** Foreign key from dimension table. Based on type in Service table and the age of the car
  calculated from car_year in Car table and start_date in Service table in RentMaster source.
- **ServiceNo:** Taken from service_id column in Service table in RentMaster source.
- **Cost:** Taken from cost column in Service table in RentMaster source.
- **ServiceDays:** Calculated as the number of days between start_date and end_date in Service table in
  RentMaster source.
- **Mileage:** Taken from mileage column in Service table in RentMaster source.
- **KmSinceLastService:** Calculated as the difference between mileage of the service and mileage of the
  previous service of the same car in Service table in RentMaster source (for the first service: the
  difference to mileage_before of the first rent of the car in Rent table).
- **DaysSinceLastService:** Calculated as the number of days between start_date of the service and
  end_date of the previous service of the same car in Service table in RentMaster source (for the first
  service: the number of days since the car entered the fleet).

**CAR_STATUS**

The tuples are generated for every car and every day the car is in the fleet: from 1 January of
car_year (or the first day of data) in Car table to the last day of data.

- **Id_Date:** Foreign key from dimension table. Generated day by day.
- **Id_Car:** Foreign key from dimension table. Based on licence_plate in Car table in RentMaster source and
  the version of the car valid on the day.
- **Id_Employee:** Foreign key from dimension table. Based on employee_id of the rent from Rent table in
  RentMaster source covering the day (special tuple "not rented" if there is no such rent).
- **Id_Client:** Foreign key from dimension table. Based on client_PESEL of the rent from Rent table in
  RentMaster source covering the day (special tuple "not rented" if there is no such rent).
- **Id_Junk:** Foreign key from dimension table. Based on Mileage of the tuple and the age of the car
  calculated from car_year in Car table in RentMaster source and the day.
- **RentedDay:** 1 if the day is between date_issued (inclusive) and date_returned_actual (exclusive) of
  any rent of the car in Rent table in RentMaster source, otherwise 0.
- **ServiceDay:** 1 if the day is between start_date and end_date (inclusive) of any service of the car in
  Service table in RentMaster source, otherwise 0.
- **AvailableDay:** Calculated as 1 − ServiceDay.
- **IdleDay:** Calculated as AvailableDay − RentedDay.
- **Mileage:** Based on mileage_before and mileage_after in Rent table in RentMaster source: mileage_before
  of the rent covering the day, otherwise mileage_after of the last finished rent of the car (for days
  before the first rent: mileage_before of the first rent).

**CAR SCD 2**

- **Id_Car:** Surrogate key generated by database.
- **Id_Location:** Foreign key from dimension table based on location_id in Car table in RentMaster source.
- **LicencePlate:** Business key taken from licence_plate in Car table in RentMaster source.
- **Brand:** Taken from Brand column in Car table in RentMaster source.
- **Model:** Taken from Model column in Car table in RentMaster source.
- **Type:** Taken from type column in Car table in RentMaster source.
- **FuelType:** Taken from fuel_type column in Car table in RentMaster source.
- **Color:** Taken from Color column in Car table in RentMaster source.
- **ProductionYear:** Taken from car_year column in Car table in RentMaster source.
- **PriceCategory:** Derived from Price_per_day in Car table in RentMaster source:
    - < 200: economy
    - < 300: standard
    - < 400: premium
    - >= 400: luxury
- **IsCurrent:** '1' if information is current, otherwise '0'. A new tuple is created when the rental point
  (location_id) or the price category of the car changes.

**LOCATION**

- **Id_Location:** Surrogate key generated by database.
- **LocationName:** Business key taken from Name column in Location table in RentMaster source.
- **City:** Taken from City column in Location table in RentMaster source.
- **District:** Derived from Name column in Location table in RentMaster source (the part after the city
  name, e.g. "SigmaPol Kraków Nowa Huta" → Nowa Huta).
- **Street:** Taken from Street column in Location table in RentMaster source (overwritten when the
  rental point moves to a new address).
- **Status:** 'open' if the rental point exists in Location table in RentMaster source, 'closed' if it was
  removed from the table.

**EMPLOYEE SCD 2**

- **Id_Employee:** Surrogate key generated by database.
- **Id_Location:** Foreign key from dimension table based on location_id in Employee table in RentMaster
  source.
- **EmployeeNo:** Business key taken from employee_id in Employee table in RentMaster source.
- **Name:** Taken from Name column in Employee table in RentMaster source.
- **Surname:** Taken from Surname column in Employee table in RentMaster source.
- **NameAndSurname:** Taken from Name and Surname columns in Employee table in RentMaster source.
- **IsCurrent:** '1' if information is current, otherwise '0'. A new tuple is created when the employee
  moves to another rental point (location_id changes).

**CLIENT SCD 2**

- **Id_Client:** Surrogate key generated by database.
- **PID:** Business key taken from column C (PESEL) of Sheet 1 in CEO Excel source.
- **Name:** Taken from column A of Sheet 1 in CEO Excel source.
- **Surname:** Taken from column B of Sheet 1 in CEO Excel source (overwritten when changed).
- **NameAndSurname:** Taken from columns A and B of Sheet 1 in CEO Excel source.
- **Gender:** Taken from column E of Sheet 1 in CEO Excel source.
- **DateOfBirth:** Calculated from column C (PESEL) of Sheet 1 in CEO Excel source (first 6 digits).
- **AgeCategory:** Calculated from DateOfBirth and the date of the rent.
- **IsCurrent:** '1' if information is current, otherwise '0'. A new tuple is created when the client moves
  to the next age category.

**DATE, TIME, JUNK**

- **DATE:** Generated tuple by tuple based on calendar prior to ETL. Holiday, BeforeHolidayDay and Vacation
  are based on the public calendar of Polish public holidays and school holidays (e.g. Google Calendar).
- **TIME:** Generated tuple by tuple based on clock prior to ETL.
- **JUNK_RENT:** Generated with all combinations of ReturnStatus and RentalLength prior to ETL.
- **JUNK_SERVICE:** Generated with all combinations of ServiceType and CarAgeCategory prior to ETL
  (ServiceKind: 'planned' for routine, 'unexpected' for accident and malfunction).
- **JUNK_CARSTATUS:** Generated with all combinations of MileageCategory and CarAgeCategory prior to ETL.

**Data not available in data sources**

- Client's satisfaction with a rented car (analytical question 1.6) is not stored in any data source.
  It requires introducing the post-rental survey described in the requirements specification.
- Client's phone number and driver's licence number (columns F and G of Sheet 1 in CEO Excel source) are
  available, but they are not needed for any analytical question, so they are not loaded into the data
  warehouse.
