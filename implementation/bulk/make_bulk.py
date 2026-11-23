# Sample data for the SigmaPol data warehouse (for validation only, not the real ETL).
# Writes one CSV per warehouse table into this folder. Dimensions are referenced in CAR_DAY.csv
# by business keys (plus the attributes that select the SCD2 version), like in the example project.
# Period: 2025-12-01 .. 2026-02-28 (crosses the year boundary, so both yearly partitions are used).
# SCD2 changes in the sample:
#  - car CB 40001 moves from the closed rental point Fordon to Śródmieście on 2026-01-01,
#  - car CB 40002 gets a higher daily price (standard -> premium) on 2026-02-01,
#  - employee 6 moves from Fordon to Śródmieście on 2026-01-01,
#  - client Jakub Kozłowski turns 25 on 2026-01-20 (18-24 -> 25-34).
# Usage: python make_bulk.py

import csv
import random
from datetime import date, timedelta
from itertools import product
from pathlib import Path

random.seed(7)
OUT = Path(__file__).resolve().parent
START, END = date(2025, 12, 1), date(2026, 2, 28)
CAL_START, CAL_END = date(2025, 1, 1), date(2026, 12, 31)
NOT_RENTED_PID = "00000000000"


def write(name, header, rows):
    with open(OUT / name, "w", newline="", encoding="cp1250") as f:   # cp1250 = Polish_CI_AS, loaded with CODEPAGE = 'RAW'
        w = csv.writer(f, lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)


def days(a, b):
    while a <= b:
        yield a
        a += timedelta(days=1)


# ---------- LOCATION ----------
LOCATIONS = [  # name, city, district, street, status
    ("SigmaPol Warszawa Mokotów", "Warszawa", "Mokotów", "Puławska 12", "open"),
    ("SigmaPol Warszawa Wola", "Warszawa", "Wola", "Prosta 51", "open"),
    ("SigmaPol Kraków Nowa Huta", "Kraków", "Nowa Huta", "Mogilska 40", "open"),
    ("SigmaPol Bydgoszcz Śródmieście", "Bydgoszcz", "Śródmieście", "Gdańska 7", "open"),
    ("SigmaPol Bydgoszcz Fordon", "Bydgoszcz", "Fordon", "Fordońska 88", "closed"),
]
MOKOTOW, WOLA, NOWA_HUTA, SRODMIESCIE, FORDON = (l[0] for l in LOCATIONS)
write("LOCATION.csv", ["LocationName", "City", "District", "Street", "Status"], LOCATIONS)


# ---------- CAR (SCD2 on rental point and price category) ----------
def price_category(price):
    return "economy" if price < 200 else "standard" if price < 300 else "premium" if price < 400 else "luxury"


# plate, brand, model, type, fuel, color, year, mileage on START, km since the last service on START,
# versions: [(valid from, rental point, daily price)]
CARS = [
    ("WA 10001", "Toyota", "Corolla", "sedan", "hybrid", "white", 2025, 9000, 9000, [(START, MOKOTOW, 150)]),
    ("WA 10002", "BMW", "X5", "suv", "diesel", "black", 2022, 61000, 4000, [(START, MOKOTOW, 420)]),
    ("WA 20001", "Skoda", "Octavia", "combi", "petrol", "silver", 2020, 118000, 13500, [(START, WOLA, 170)]),
    ("WA 20002", "Volkswagen", "Transporter", "van", "diesel", "white", 2018, 214000, 14200, [(START, WOLA, 270)]),
    ("KR 30001", "Kia", "Sportage", "suv", "LPG", "red", 2023, 42000, 7000, [(START, NOWA_HUTA, 240)]),
    ("KR 30002", "Porsche", "911", "sport", "petrol", "grey", 2024, 21000, 11000, [(START, NOWA_HUTA, 480)]),
    ("KR 30003", "Toyota", "RAV4", "suv", "hybrid", "white", 2026, 20, 20, [(date(2026, 1, 1), NOWA_HUTA, 235)]),
    ("CB 40001", "Ford", "Focus", "combi", "petrol", "blue", 2021, 96000, 12000,
     [(START, FORDON, 165), (date(2026, 1, 1), SRODMIESCIE, 165)]),
    ("CB 40002", "Audi", "A4", "sedan", "electric", "black", 2025, 15000, 15000,
     [(START, SRODMIESCIE, 290), (date(2026, 2, 1), SRODMIESCIE, 319)]),
]


def car_version(car, day):
    return [v for v in car[9] if v[0] <= day][-1]


car_rows = []
for c in CARS:
    for i, (_, loc, price) in enumerate(c[9]):
        car_rows.append([c[0], loc, c[1], c[2], c[3], c[4], c[5], c[6], price_category(price), int(i == len(c[9]) - 1)])
write("CAR.csv", ["LicencePlate", "LocationName", "Brand", "Model", "Type", "FuelType", "Color", "ProductionYear",
                  "PriceCategory", "IsCurrent"], car_rows)

# ---------- EMPLOYEE (SCD2 on rental point, special tuple "not rented") ----------
EMPLOYEES = [  # employee no, name, surname, versions: [(valid from, rental point)]
    (1, "Jan", "Nowak", [(START, MOKOTOW)]),
    (2, "Anna", "Kowalska", [(START, MOKOTOW)]),
    (3, "Piotr", "Wiśniewski", [(START, WOLA)]),
    (4, "Ewa", "Dąbrowska", [(START, WOLA)]),
    (5, "Katarzyna", "Wójcik", [(START, NOWA_HUTA)]),
    (6, "Magdalena", "Zielińska", [(START, FORDON), (date(2026, 1, 1), SRODMIESCIE)]),
    (7, "Łukasz", "Mazur", [(START, SRODMIESCIE)]),
    (8, "Tomasz", "Kamiński", [(START, NOWA_HUTA)]),
]
emp_rows = [["", 0, "not rented", "not rented", "not rented", 1]]
for no, name, surname, versions in EMPLOYEES:
    for i, (_, loc) in enumerate(versions):
        emp_rows.append([loc, no, name, surname, f"{name} {surname}", int(i == len(versions) - 1)])
write("EMPLOYEE.csv", ["LocationName", "EmployeeNo", "Name", "Surname", "NameAndSurname", "IsCurrent"], emp_rows)


def employee_location(emp, day):
    return [v for v in emp[3] if v[0] <= day][-1][1]


# ---------- CLIENT (SCD2 on age category, special tuple "not rented") ----------
def make_pesel(birth, male):
    month = birth.month + (20 if birth.year >= 2000 else 0)
    digits = f"{birth.year % 100:02d}{month:02d}{birth.day:02d}{random.randint(0, 999):03d}{random.choice([1, 3, 5, 7, 9] if male else [0, 2, 4, 6, 8])}"
    s = sum(int(d) * w for d, w in zip(digits, [1, 3, 7, 9, 1, 3, 7, 9, 1, 3]))
    return digits + str((10 - s % 10) % 10)


def age_category(birth, day):
    age = day.year - birth.year - ((day.month, day.day) < (birth.month, birth.day))
    for limit, cat in ((24, "18-24"), (34, "25-34"), (44, "35-44"), (54, "45-54"), (64, "55-64")):
        if age <= limit:
            return cat
    return "65+"


CLIENTS = []
for name, surname, male, birth in [
    ("Jakub", "Kozłowski", True, date(2001, 1, 20)),
    ("Zofia", "Lewandowska", False, date(2004, 5, 3)),
    ("Adam", "Szymański", True, date(1996, 8, 11)),
    ("Maria", "Woźniak", False, date(1990, 3, 2)),
    ("Michał", "Krawczyk", True, date(1985, 11, 30)),
    ("Barbara", "Jankowska", False, date(1978, 7, 14)),
    ("Andrzej", "Piotrowski", True, date(1968, 2, 25)),
    ("Joanna", "Mazur", False, date(1964, 9, 9)),
    ("Krzysztof", "Kowalczyk", True, date(1958, 12, 5)),
    ("Ewa", "Nowak", False, date(1955, 4, 18)),
    ("Mateusz", "Wójcik", True, date(2003, 10, 1)),
    ("Aleksandra", "Zielińska", False, date(1993, 6, 21)),
]:
    CLIENTS.append({"pid": make_pesel(birth, male), "name": name, "surname": surname,
                    "gender": "male" if male else "female", "birth": birth})

client_rows = [[NOT_RENTED_PID, "not rented", "not rented", "not rented", "not rented", "", "not rented", 1]]
for c in CLIENTS:
    cats = sorted({age_category(c["birth"], d) for d in days(START, END)})
    for i, cat in enumerate(cats):
        client_rows.append([c["pid"], c["name"], c["surname"], f"{c['name']} {c['surname']}", c["gender"],
                            c["birth"], cat, int(i == len(cats) - 1)])
write("CLIENT.csv", ["PID", "Name", "Surname", "NameAndSurname", "Gender", "DateOfBirth", "AgeCategory", "IsCurrent"],
      client_rows)


# ---------- DATE ----------
def easter(year):
    a, b, c = year % 19, year // 100, year % 100
    d, e = b // 4, b % 4
    g = (8 * b + 13) // 25
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 19 * l) // 433
    month = (h + l - 7 * m + 90) // 25
    return date(year, month, (h + l - 7 * m + 33 * month + 19) % 32)


def holidays(year):
    e = easter(year)
    return {date(year, 1, 1): "New Year", date(year, 1, 6): "Epiphany", e: "Easter",
            e + timedelta(days=1): "Easter Monday", date(year, 5, 1): "Labour Day",
            date(year, 5, 3): "Constitution Day", e + timedelta(days=49): "Pentecost",
            e + timedelta(days=60): "Corpus Christi", date(year, 8, 15): "Assumption Day",
            date(year, 11, 1): "All Saints' Day", date(year, 11, 11): "Independence Day",
            date(year, 12, 24): "Christmas Eve", date(year, 12, 25): "Christmas",
            date(year, 12, 26): "Second Day of Christmas"}


HOLIDAYS = {**holidays(2025), **holidays(2026), **holidays(2027)}
# school holidays (winter break across all voivodeships and Christmas break, summer break)
WINTER = [(date(2025, 1, 20), date(2025, 3, 2)), (date(2025, 12, 22), date(2025, 12, 31)),
          (date(2026, 1, 19), date(2026, 3, 1)), (date(2026, 12, 22), date(2026, 12, 31))]
SUMMER = [(date(2025, 6, 28), date(2025, 8, 31)), (date(2026, 6, 27), date(2026, 8, 31))]
SEASONS = {12: "winter", 1: "winter", 2: "winter", 3: "spring", 4: "spring", 5: "spring",
           6: "summer", 7: "summer", 8: "summer", 9: "autumn", 10: "autumn", 11: "autumn"}

date_rows = []
for d in days(CAL_START, CAL_END):
    holiday = HOLIDAYS.get(d, "none")
    tomorrow = HOLIDAYS.get(d + timedelta(days=1))
    vacation = ("winter holiday" if any(a <= d <= b for a, b in WINTER) else
                "summer holiday" if any(a <= d <= b for a, b in SUMMER) else "non-holiday")
    date_rows.append([d, d.year, (d.month - 1) // 3 + 1, d.strftime("%B"), d.month, d.strftime("%A"), d.isoweekday(),
                      "day off" if d.isoweekday() >= 6 or holiday != "none" else "working day",
                      SEASONS[d.month], vacation, holiday, f"tomorrow is {tomorrow}" if tomorrow else "none"])
write("DATE.csv", ["Date", "Year", "Quarter", "Month", "MonthNo", "DayOfWeek", "DayOfWeekNo", "WorkingDay", "Season",
                   "Vacation", "Holiday", "BeforeHolidayDay"], date_rows)


# ---------- TIME (special tuple "no rent") ----------
def time_of_day(h):
    return ("between 0 and 8" if h <= 8 else "between 9 and 12" if h <= 12 else "between 13 and 15" if h <= 15
            else "between 16 and 20" if h <= 20 else "between 21 and 23")


write("TIME.csv", ["Hour", "TimeOfDay"], [[h, time_of_day(h)] for h in range(24)] + [["", "no rent"]])

# ---------- JUNK (all combinations) ----------
RETURN_STATUS = ["on time", "late", "not rented"]
RENTAL_LENGTH = ["1 to 3 days", "4 to 7 days", "8 to 14 days", "more than 14 days", "not rented"]
SERVICE_TYPE = {"routine": "planned", "accident": "unexpected", "malfunction": "unexpected", "none": "none"}
MILEAGE = ["up to 50 000 km", "50 000 to 100 000 km", "100 000 to 200 000 km", "over 200 000 km"]
CAR_AGE = ["up to 1 year", "1 to 3 years", "3 to 5 years", "over 5 years"]
write("JUNK.csv", ["ReturnStatus", "RentalLength", "ServiceType", "ServiceKind", "MileageCategory", "CarAgeCategory"],
      [[r, l, s, SERVICE_TYPE[s], m, a] for r, l, s, m, a in product(RETURN_STATUS, RENTAL_LENGTH, SERVICE_TYPE, MILEAGE, CAR_AGE)])


def rental_length(n):
    return "1 to 3 days" if n <= 3 else "4 to 7 days" if n <= 7 else "8 to 14 days" if n <= 14 else "more than 14 days"


def mileage_category(km):
    return MILEAGE[0] if km < 50000 else MILEAGE[1] if km < 100000 else MILEAGE[2] if km < 200000 else MILEAGE[3]


def car_age(year, day):
    age = (day - date(year, 1, 1)).days / 365.25
    return CAR_AGE[0] if age <= 1 else CAR_AGE[1] if age <= 3 else CAR_AGE[2] if age <= 5 else CAR_AGE[3]


# ---------- CAR_DAY (simulation of rents and services, day by day) ----------
DEMAND = {MOKOTOW: 0.75, WOLA: 0.55, NOWA_HUTA: 0.45, SRODMIESCIE: 0.4, FORDON: 0.3}   # chance of a new rent per idle day
SERVICE_DAYS = {"routine": (1, 2), "malfunction": (2, 6), "accident": (5, 12)}
SERVICE_COST = {"routine": (400, 1200), "malfunction": (500, 3000), "accident": (2000, 15000)}

client_busy = {c["pid"]: START for c in CLIENTS}   # client -> first day they are free again
rent_no, service_no, fact_rows = 1000, 200, []
for car in CARS:
    plate, year = car[0], car[6]
    km, since_service = car[7], car[8]
    rent, service, problem = None, None, None
    for d in days(car[9][0][0], END):
        _, loc, price = car_version(car, d)
        if rent and d >= rent["returned"]:   # car returned in the morning, mileage after the rent
            km = rent["before"] + rent["km"]
            since_service += rent["km"]
            rent = None
        if service and d > service["end"]:
            service = None
        if not rent and not service and (problem or since_service >= 15000):   # service starts
            kind = problem or "routine"
            service_no += 1
            service = {"no": service_no, "type": kind, "start": d, "km_since": since_service,
                       "end": d + timedelta(days=random.randint(*SERVICE_DAYS[kind]) - 1),
                       "cost": random.randint(*SERVICE_COST[kind])}
            since_service, problem = 0, None
        if not rent and not service and random.random() < DEMAND[loc]:   # rent starts
            free = [c for c in CLIENTS if client_busy[c["pid"]] <= d]
            if free:
                client = random.choice(free)
                planned = random.choice([1, 2, 3, 3, 4, 5, 7, 7, 10, 14, 21])
                delay = random.randint(1, 3) if random.random() < 0.12 else 0
                rent_no += 1
                rent = {"no": rent_no, "client": client, "issued": d, "hour": random.randint(8, 19),
                        "days": planned + delay, "delay": delay, "returned": d + timedelta(days=planned + delay),
                        "before": km, "km": (planned + delay) * random.randint(40, 250), "cost": (planned + delay) * price,
                        "employee": random.choice([e for e in EMPLOYEES if employee_location(e, d) == loc])}
                client_busy[client["pid"]] = rent["returned"]
                r = random.random()
                problem = "accident" if r < 0.05 else "malfunction" if r < 0.12 else None
                rent["survey"] = random.random() < 0.65
                rent["issues"] = int(problem is not None or random.random() < 0.1)
                rent["rating"] = random.choice([1, 2, 3]) if rent["issues"] else random.choice([3, 4, 4, 5, 5])
                rent["again"] = max(1, min(5, rent["rating"] + random.choice([-1, 0, 0, 1])))

        rented, in_service = int(rent is not None), int(service is not None)
        started = int(rent is not None and rent["issued"] == d)
        service_started = int(service is not None and service["start"] == d)
        mileage = rent["before"] if rent else km
        survey = started and rent["survey"]
        emp = rent["employee"] if rent else None
        fact_rows.append([
            d, plate, loc, price_category(price),
            emp[0] if emp else 0, employee_location(emp, d) if emp else "",
            rent["client"]["pid"] if rent else NOT_RENTED_PID,
            age_category(rent["client"]["birth"], d) if rent else "not rented",
            rent["hour"] if started else "",
            ("late" if rent["delay"] else "on time") if rent else "not rented",
            rental_length(rent["days"]) if rent else "not rented",
            service["type"] if service else "none",
            mileage_category(mileage), car_age(year, d),
            rent["no"] if rent else "", service["no"] if service else "",
            rented, in_service, 1 - in_service, 1 - in_service - rented,
            mileage, round(rent["km"] / rent["days"], 2) if rent else 0,
            started, f"{rent['cost']:.2f}" if started else "0.00", rent["days"] if started else 0,
            rent["delay"] if started else 0,
            service_started, f"{service['cost']:.2f}" if service_started else "0.00",
            service["km_since"] if service_started else 0,
            int(bool(survey)), rent["rating"] if survey else 0, rent["issues"] if survey else 0,
            rent["again"] if survey else 0,
        ])

write("CAR_DAY.csv", [
    "Date", "LicencePlate", "CarLocationName", "PriceCategory", "EmployeeNo", "EmployeeLocationName", "PID",
    "ClientAgeCategory", "IssueHour", "ReturnStatus", "RentalLength", "ServiceType", "MileageCategory",
    "CarAgeCategory", "RentNo", "ServiceNo", "RentedDay", "ServiceDay", "AvailableDay", "IdleDay", "Mileage",
    "KmDriven", "RentStarted", "RentCost", "RentalDays", "DelayDays", "ServiceStarted", "ServiceCost",
    "KmSinceLastService", "SurveyAnswered", "CarConditionRating", "IssuesReported", "LikelihoodToRentAgain",
], fact_rows)

print(f"{len(fact_rows)} car days, {rent_no - 1000} rents, {service_no - 200} services")
