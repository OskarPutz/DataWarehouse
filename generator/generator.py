# Data generator for RentMaster (.bulk files for BULK INSERT, columns separated by |) and CEO Excel (clients.xlsx).
# T1 = START..CUTOFF-1 (2020-2025), T2 = START..END (2020-2026).
# T2 = T1 + new rows + changed rows + deleted rows:
#  - rental points: one is closed, one moves to a new address,
#  - employees: some move to another rental point (everyone from the closed one too), new employees,
#  - cars: some move to another rental point, new daily prices, current mileage, new cars,
#  - clients: new phone numbers, driving licences and surnames, new clients.
# Employees and cars are never deleted - old rents and services refer to them.
# A client is entered into the CEO Excel sheet with their first rent, so every client in the sheet has rented a car.
# Usage: python generator.py [number_of_rents]

import random
import sys
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path

from openpyxl import Workbook

ROWS = int(sys.argv[1]) if len(sys.argv) > 1 else 100000
START = date(2020, 1, 1)    # first day of data
CUTOFF = date(2026, 1, 1)   # first day after T1
END = date(2026, 10, 25)    # last day of T2
MIN_AGE = 21                # minimum age of a client
OUT = Path(__file__).resolve().parent / "output"

# T2 changes in rental points
CLOSED, TAKEN_OVER_BY = "Fordon", "Śródmieście"   # closed on CUTOFF, its employees and cars go to the other one
NEW_ADDRESS = {"Wola": "Prosta 51"}                 # moved to a new address

random.seed(42)

CITIES = {
    "Warszawa": ("WA", ["Mokotów", "Wola", "Praga"], ["Puławska", "Wolska", "Targowa", "Marszałkowska"]),
    "Kraków": ("KR", ["Stare Miasto", "Nowa Huta", "Podgórze"], ["Floriańska", "Kalwaryjska", "Mogilska"]),
    "Bydgoszcz": ("CB", ["Fordon", "Śródmieście"], ["Gdańska", "Fordońska", "Jagiellońska"]),
    "Gdańsk": ("GD", ["Wrzeszcz", "Oliwa", "Przymorze"], ["Grunwaldzka", "Słowackiego", "Kołobrzeska"]),
    "Poznań": ("PO", ["Jeżyce", "Wilda", "Grunwald"], ["Dąbrowskiego", "Górna Wilda", "Głogowska"]),
}

MALE_NAMES = ["Jan", "Piotr", "Krzysztof", "Andrzej", "Tomasz", "Paweł", "Michał", "Marcin", "Jakub", "Adam", "Łukasz", "Mateusz"]
FEMALE_NAMES = ["Anna", "Maria", "Katarzyna", "Małgorzata", "Agnieszka", "Barbara", "Ewa", "Magdalena", "Joanna", "Zofia", "Aleksandra"]
SURNAMES = [("Nowak", "Nowak"), ("Kowalski", "Kowalska"), ("Wiśniewski", "Wiśniewska"), ("Wójcik", "Wójcik"),
            ("Kowalczyk", "Kowalczyk"), ("Kamiński", "Kamińska"), ("Lewandowski", "Lewandowska"), ("Zieliński", "Zielińska"),
            ("Szymański", "Szymańska"), ("Woźniak", "Woźniak"), ("Dąbrowski", "Dąbrowska"), ("Kozłowski", "Kozłowska"),
            ("Jankowski", "Jankowska"), ("Mazur", "Mazur"), ("Krawczyk", "Krawczyk"), ("Piotrowski", "Piotrowska")]

MODELS = [("Toyota", "Corolla", "sedan"), ("Toyota", "RAV4", "suv"), ("Skoda", "Octavia", "combi"),
          ("Skoda", "Superb", "sedan"), ("Volkswagen", "Passat", "combi"), ("Volkswagen", "Transporter", "van"),
          ("Ford", "Focus", "combi"), ("Ford", "Mustang", "sport"), ("BMW", "M4", "coupe"), ("BMW", "X5", "suv"),
          ("Audi", "A4", "sedan"), ("Kia", "Sportage", "suv"), ("Renault", "Trafic", "van"), ("Porsche", "911", "sport")]
FUELS = ["petrol"] * 35 + ["diesel"] * 30 + ["LPG"] * 10 + ["hybrid"] * 15 + ["electric"] * 10
COLORS = ["black", "white", "silver", "red", "blue", "grey"]
BASE_PRICE = {"sedan": 150, "combi": 160, "suv": 230, "van": 260, "coupe": 300, "sport": 450}
SERVICE_DAYS = {"routine": (1, 2), "malfunction": (2, 7), "accident": (5, 20)}
SERVICE_COST = {"routine": (400, 1200), "malfunction": (500, 3000), "accident": (2000, 15000)}
DESCRIPTIONS = {"routine": ["oil change", "periodic inspection", ""], "malfunction": ["brake change", "battery replacement", "clutch repair", ""],
                "accident": ["collision repair", "bumper replacement", "windshield replacement", ""]}


def make_pesel(birth, male):
    sex = random.choice([1, 3, 5, 7, 9] if male else [0, 2, 4, 6, 8])
    month = birth.month + (20 if birth.year >= 2000 else 0)  # PESEL encodes births in 2000-2099 as month + 20
    digits = f"{birth.year % 100:02d}{month:02d}{birth.day:02d}{random.randint(0, 999):03d}{sex}"
    s = sum(int(d) * w for d, w in zip(digits, [1, 3, 7, 9, 1, 3, 7, 9, 1, 3]))
    return digits + str((10 - s % 10) % 10)


def new_licence():
    return f"{random.randint(0, 99999):05d}/{random.randint(0, 99):02d}/{random.randint(0, 9999):04d}"


def new_phone():
    return str(random.randint(500000000, 899999999))


def age(birth, on):
    return on.year - birth.year - ((on.month, on.day) < (birth.month, birth.day))


def random_person():
    male = random.random() < 0.5
    surname = random.choice(SURNAMES)[0 if male else 1]
    return random.choice(MALE_NAMES if male else FEMALE_NAMES), surname, male


def fmt(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%S")


def line(row):
    return "|".join(str(x) for x in row) + "\n"


def write_lines(path, lines):
    with open(path, "w", newline="", encoding="cp1250") as f:
        f.writelines(lines)


def write_numbered(path, lines):
    write_lines(path, (f"{i}|{s}" for i, s in enumerate(lines, start=1)))


def write_excel(path, clients, on):
    wb = Workbook(write_only=True)
    ws = wb.create_sheet("Sheet 1")
    ws.append(["first_name", "last_name", "PESEL", "age", "gender", "drivers_licence_number", "phone_number"])
    for c in clients:
        ws.append([c["name"], c["surname"], c["pesel"], age(c["birth"], on), c["gender"], c["licence"], c["phone"]])
    wb.save(path)


# ---------- rental points ----------
locations, locations_t2 = [], []   # [id, city, street, name]
point = {}                         # district -> rental point id
idle_max, late_p = {}, {}
for city, (code, districts, streets) in CITIES.items():
    for district in districts:
        loc_id = point[district] = len(locations) + 1
        street = f"{random.choice(streets)} {random.randint(1, 120)}"
        locations.append([loc_id, city, street, f"SigmaPol {city} {district}"])
        if district != CLOSED:
            locations_t2.append([loc_id, city, NEW_ADDRESS.get(district, street), f"SigmaPol {city} {district}"])
        # rental points differ in demand (max idle days before the next customer) and in late returns
        idle_max[loc_id] = random.randint(1, 4)
        late_p[loc_id] = random.uniform(0.05, 0.15)
open_ids = [l[0] for l in locations_t2]


def in_t2(loc_id):
    """Rental point in T2: employees and cars of the closed one go to TAKEN_OVER_BY."""
    return point[TAKEN_OVER_BY] if loc_id == point[CLOSED] else loc_id


# ---------- employees ----------
employees = []   # "loc" = rental point in T1 and in T2
for loc in locations:
    for _ in range(4):
        name, surname, _ = random_person()
        employees.append({"id": len(employees) + 1, "name": name, "surname": surname, "loc": {1: loc[0], 2: in_t2(loc[0])}})

# T2 changes: 3 employees moved to another rental point, 1 new employee in every open rental point
for e in random.sample(employees, 3):
    e["loc"][2] = random.choice([i for i in open_ids if i != e["loc"][2]])
for loc_id in open_ids:
    name, surname, _ = random_person()
    employees.append({"id": len(employees) + 1, "name": name, "surname": surname, "loc": {1: None, 2: loc_id}})

staff = {1: defaultdict(list), 2: defaultdict(list)}   # snapshot -> rental point -> employee ids
for e in employees:
    for t in (1, 2):
        if e["loc"][t]:
            staff[t][e["loc"][t]].append(e["id"])

# ---------- clients (CEO Excel) ----------
CLIENTS = max(100, ROWS // 20)
T1_CLIENTS = CLIENTS * (CUTOFF - START).days // (END - START).days   # can rent from START, the rest from CUTOFF

clients, pesels = [], set()
while len(clients) < CLIENTS:
    name, surname, male = random_person()
    # every client is at least MIN_AGE on the first day they can rent: START for T1 clients, CUTOFF for new ones
    first_day = START if len(clients) < T1_CLIENTS else CUTOFF
    birth = first_day.replace(year=first_day.year - MIN_AGE) - timedelta(days=random.randint(0, 50 * 365))
    pesel = make_pesel(birth, male)
    if pesel in pesels:
        continue
    pesels.add(pesel)
    clients.append({"name": name, "surname": surname, "pesel": pesel, "birth": birth, "gender": "male" if male else "female",
                    "licence": new_licence(), "phone": new_phone()})
renting = {1: clients[:T1_CLIENTS], 2: clients}   # clients who can rent in T1 / in T2

# ---------- cars, rents and services ----------
cars, plates = [], set()
rents_t1, rents_new, services_t1, services_new = [], [], [], []   # ready .bulk lines without ids
client_rents = defaultdict(list)   # pesel -> [(issued, returned)], so a client never has two cars at once

while len(rents_t1) + len(rents_new) < ROWS:
    brand, model, car_type = random.choice(MODELS)
    year = random.randint(START.year - 3, END.year)
    # a car is in the fleet from 1 January of its production year (or START) until END,
    # so the warehouse can derive the days it was available from Car.year
    start = max(START, date(year, 1, 1))
    loc = random.choice(locations if start < CUTOFF else locations_t2)
    plate = f"{CITIES[loc[1]][0]} {random.randint(10000, 99999)}"
    if plate in plates:
        continue
    plates.add(plate)
    km = random.randint(0, 50) + max(0, START.year - year) * random.randint(10000, 20000)
    price = BASE_PRICE[car_type] + random.randint(-20, 40)
    car = {"plate": plate, "brand": brand, "model": model, "color": random.choice(COLORS), "year": year,
           "fuel": random.choice(FUELS), "type": car_type, "start": start,
           "loc": {1: loc[0], 2: in_t2(loc[0])}, "price": {1: price, 2: price}, "km": {1: km, 2: km}}
    # T2 changes for cars already in T1: moved to another rental point or a new daily price
    if start < CUTOFF and random.random() < 0.05:
        car["loc"][2] = random.choice([i for i in open_ids if i != car["loc"][2]])
    if start < CUTOFF and random.random() < 0.10:
        car["price"][2] = round(price * 1.1)
    cars.append(car)

    day, last_km, last_service, problem = start, km, start, None
    while True:
        t = 1 if day < CUTOFF else 2
        loc_id = car["loc"][t]

        # routine service after 15 000 km or 12 months, accident / malfunction right after the rental
        if problem or km - last_km >= 15000 or (day - last_service).days >= 365:
            kind = problem or "routine"
            end = day + timedelta(days=random.randint(*SERVICE_DAYS[kind]))
            if end > END:
                break
            row = [plate, day, end, km, f"{random.randint(*SERVICE_COST[kind])}.00", kind, random.choice(DESCRIPTIONS[kind])]
            (services_t1 if end < CUTOFF else services_new).append(line(row))
            day, last_km, last_service, problem = end + timedelta(days=1), km, end, None
            continue

        days = random.randint(1, 14)
        late = random.randint(1, 3) if random.random() < late_p[loc_id] else 0
        issued = datetime(day.year, day.month, day.day, random.randint(8, 17), random.choice([0, 15, 30, 45]))
        planned = issued + timedelta(days=days)
        actual = planned + timedelta(days=late)
        if actual.date() > END:
            break

        for _ in range(1000):   # a client without another car at that time - practically always the first try
            client = random.choice(renting[t])
            if all(actual <= s or issued >= e for s, e in client_rents[client["pesel"]]):
                break
        client_rents[client["pesel"]].append((issued, actual))

        driven = (days + late) * random.randint(30, 250)
        # cost = daily price x actual number of days
        row = [client["pesel"], plate, random.choice(staff[t][loc_id]), fmt(issued), fmt(planned), fmt(actual),
               f"{(days + late) * car['price'][t]}.00", km, km + driven]
        km += driven
        car["km"][2] = km
        if actual.date() < CUTOFF:
            rents_t1.append(line(row))
            car["km"][1] = km
        else:
            rents_new.append(line(row))

        r = random.random()
        problem = "accident" if r < 0.01 else "malfunction" if r < 0.03 else None
        # next customer after an idle time that depends on the rental point; shorter in summer and in December
        idle = 0 if problem else random.randint(0, idle_max[loc_id]) // (2 if day.month in (6, 7, 8, 12) else 1)
        day = actual.date() + timedelta(days=1 + idle)

# CEO Excel: a client is in the sheet from their first rent (T2 rows are copies, so T2 changes do not touch T1)
excel = {1: [c for c in clients if any(s.date() < CUTOFF for s, _ in client_rents[c["pesel"]])],
         2: [dict(c) for c in clients if client_rents[c["pesel"]]]}

# T2 changes in CEO Excel: some clients have a new phone number or driving licence, some women a new surname
for c in excel[2]:
    if random.random() < 0.03:
        c["phone"] = new_phone()
    if random.random() < 0.02:
        c["licence"] = new_licence()
    if c["gender"] == "female" and random.random() < 0.02:
        c["surname"] = random.choice([s[1] for s in SURNAMES if s[1] != c["surname"]])

# ---------- write snapshots (T2 rents and services = T1 rows with the same ids + new rows) ----------
for t, snapshot in ((1, "T1"), (2, "T2")):
    folder = OUT / snapshot
    folder.mkdir(parents=True, exist_ok=True)
    write_lines(folder / "location.bulk", map(line, locations if t == 1 else locations_t2))
    write_lines(folder / "employee.bulk", (line([e["id"], e["name"], e["surname"], e["loc"][t]])
                                           for e in employees if e["loc"][t]))
    write_lines(folder / "car.bulk", (line([c["plate"], c["loc"][t], c["brand"], c["model"], c["color"], c["km"][t],
                                            f"{c['price'][t]}.00", c["year"], c["fuel"], c["type"]])
                                      for c in cars if t == 2 or c["start"] < CUTOFF))
    write_numbered(folder / "service.bulk", services_t1 if t == 1 else services_t1 + services_new)
    write_numbered(folder / "rent.bulk", rents_t1 if t == 1 else rents_t1 + rents_new)
    write_excel(folder / "clients.xlsx", excel[t], CUTOFF - timedelta(days=1) if t == 1 else END)

print(f"T1: {len(rents_t1)} rents, {len(services_t1)} services, {len(excel[1])} clients")
print(f"T2: {len(rents_t1) + len(rents_new)} rents, {len(services_t1) + len(services_new)} services, "
      f"{len(excel[2])} clients, {len(cars)} cars")
