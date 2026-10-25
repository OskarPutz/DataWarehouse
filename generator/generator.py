# Data generator for RentMaster (.bulk files for BULK INSERT, columns separated by |) and CEO Excel (clients.xlsx).
# T1 = 2010-2014, T2 = 2010-2020 (T1 + new rows + changes in dimensions).
# Usage: python generator.py [number_of_rents]

import os
import random
import shutil
import sys
from datetime import date, datetime, timedelta

from openpyxl import Workbook

ROWS = int(sys.argv[1]) if len(sys.argv) > 1 else 100000
START = date(2010, 1, 1)
CUTOFF = date(2015, 1, 1)
END = date(2020, 12, 31)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")

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
    digits = f"{birth.year % 100:02d}{birth.month:02d}{birth.day:02d}{random.randint(0, 999):03d}{sex}"
    s = sum(int(d) * w for d, w in zip(digits, [1, 3, 7, 9, 1, 3, 7, 9, 1, 3]))
    return digits + str((10 - s % 10) % 10)


def age(birth, on):
    return on.year - birth.year - ((on.month, on.day) < (birth.month, birth.day))


def fmt(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%S")


def line(row):
    return "|".join(str(x) for x in row) + "\n"


def write_bulk(path, rows):
    with open(path, "w", newline="", encoding="cp1250") as f:
        for row in rows:
            f.write(line(row))


def write_excel(path, clients, on):
    wb = Workbook(write_only=True)
    ws = wb.create_sheet("Sheet 1")
    ws.append(["first_name", "last_name", "PESEL", "age", "gender", "drivers_licence_number", "phone_number"])
    for c in clients:
        ws.append([c["name"], c["surname"], c["pesel"], age(c["birth"], on), c["gender"], c["licence"], c["phone"]])
    wb.save(path)


def random_person():
    male = random.random() < 0.5
    surname = random.choice(SURNAMES)[0 if male else 1]
    return random.choice(MALE_NAMES if male else FEMALE_NAMES), surname, male


# ---------- locations and employees ----------
locations = []
for city, (code, districts, streets) in CITIES.items():
    for district in districts:
        street = f"{random.choice(streets)} {random.randint(1, 120)}"
        locations.append([len(locations) + 1, city, street, f"SigmaPol {city} {district}"])

employees = []
for loc in locations:
    for _ in range(4):
        name, surname, _ = random_person()
        employees.append({"id": len(employees) + 1, "name": name, "surname": surname, "loc_t1": loc[0], "loc_t2": loc[0]})

# T2 changes: 3 employees moved to another rental point, 1 new employee in every rental point
for e in random.sample(employees, 3):
    e["loc_t2"] = random.choice([l[0] for l in locations if l[0] != e["loc_t1"]])
t1_employee_count = len(employees)
for loc in locations:
    name, surname, _ = random_person()
    employees.append({"id": len(employees) + 1, "name": name, "surname": surname, "loc_t1": None, "loc_t2": loc[0]})

employees_at = {1: {}, 2: {}}
for e in employees:
    if e["loc_t1"]:
        employees_at[1].setdefault(e["loc_t1"], []).append(e["id"])
    employees_at[2].setdefault(e["loc_t2"], []).append(e["id"])

# ---------- clients (CEO Excel) ----------
clients = []
pesels = set()
while len(clients) < max(100, ROWS // 20):
    name, surname, male = random_person()
    birth = date(1940, 1, 1) + timedelta(days=random.randint(0, 20800))
    pesel = make_pesel(birth, male)
    if pesel in pesels:
        continue
    pesels.add(pesel)
    clients.append({"name": name, "surname": surname, "pesel": pesel, "birth": birth, "gender": "male" if male else "female",
                    "licence": f"{random.randint(0, 99999):05d}/{random.randint(0, 99):02d}/{random.randint(0, 9999):04d}",
                    "phone": str(random.randint(500000000, 899999999))})
t1_clients = clients[: len(clients) * 55 // 100]

# ---------- cars, rents and services ----------
os.makedirs(os.path.join(OUT, "T1"), exist_ok=True)
os.makedirs(os.path.join(OUT, "T2"), exist_ok=True)
rent_t1 = open(os.path.join(OUT, "T1", "rent.bulk"), "w", newline="", encoding="cp1250")
rent_new = open(os.path.join(OUT, "rent_new.tmp"), "w", newline="", encoding="cp1250")

cars = []
plates = set()
services_t1, services_new = [], []
rents_t1_count, rents_count = 0, 0

while rents_count < ROWS:
    brand, model, car_type = random.choice(MODELS)
    year = random.randint(2004, 2020)
    loc = random.choice(locations)
    plate = f"{CITIES[loc[1]][0]} {random.randint(10000, 99999)}"
    if plate in plates:
        continue
    plates.add(plate)
    price = BASE_PRICE[car_type] + random.randint(-20, 40)
    start = START if year <= 2010 else date(year, random.randint(1, 12), 1)
    km = random.randint(0, 50) + max(0, 2010 - year) * random.randint(10000, 20000)
    car = {"plate": plate, "brand": brand, "model": model, "color": random.choice(COLORS), "year": year,
           "fuel": random.choice(FUELS), "type": car_type, "start": start, "km_t1": km,
           "loc_t1": loc[0], "loc_t2": loc[0], "price_t1": price, "price_t2": price}
    # T2 changes: some cars moved to another rental point or got a new daily price
    if start < CUTOFF and random.random() < 0.05:
        car["loc_t2"] = random.choice([l[0] for l in locations if l[0] != loc[0]])
    if start < CUTOFF and random.random() < 0.10:
        car["price_t2"] = round(price * 1.1)

    day, last_km, last_service, problem = start, km, start, None
    while True:
        if problem is None:
            day += timedelta(days=random.randint(0, 3) if day.month in (6, 7, 8, 12) else random.randint(0, 8))

        if problem or km - last_km >= 15000 or (day - last_service).days >= 365:
            kind = problem or "routine"
            end = day + timedelta(days=random.randint(*SERVICE_DAYS[kind]))
            if end > END:
                break
            row = [plate, day.isoformat(), end.isoformat(), km, f"{random.randint(*SERVICE_COST[kind])}.00", kind,
                   random.choice(DESCRIPTIONS[kind])]
            (services_t1 if end < CUTOFF else services_new).append(row)
            day, last_km, last_service, problem = end + timedelta(days=1), km, end, None
            continue

        days = random.randint(1, 14)
        late = random.randint(1, 3) if random.random() < 0.1 else 0
        issued = datetime(day.year, day.month, day.day, random.randint(8, 17), random.choice([0, 15, 30, 45]))
        planned = issued + timedelta(days=days)
        actual = planned + timedelta(days=late)
        if actual.date() > END:
            break

        period = 1 if day < CUTOFF else 2
        client = random.choice(t1_clients if period == 1 else clients)
        employee = random.choice(employees_at[period][car[f"loc_t{period}"]])
        driven = (days + late) * random.randint(30, 250)
        row = [client["pesel"], plate, employee, fmt(issued), fmt(planned), fmt(actual),
               f"{(days + late) * car[f'price_t{period}']}.00", km, km + driven]
        km += driven
        rents_count += 1
        if actual.date() < CUTOFF:
            rents_t1_count += 1
            rent_t1.write(line([rents_t1_count] + row))
            car["km_t1"] = km
        else:
            rent_new.write(line(row))

        day = actual.date() + timedelta(days=1)
        r = random.random()
        problem = "accident" if r < 0.01 else "malfunction" if r < 0.03 else None

    car["km_t2"] = km
    cars.append(car)

rent_t1.close()
rent_new.close()

# T2 rents = T1 rents + new rents with next ids
shutil.copyfile(os.path.join(OUT, "T1", "rent.bulk"), os.path.join(OUT, "T2", "rent.bulk"))
with open(os.path.join(OUT, "rent_new.tmp"), newline="", encoding="cp1250") as src, \
        open(os.path.join(OUT, "T2", "rent.bulk"), "a", newline="", encoding="cp1250") as dst:
    for i, row in enumerate(src, start=rents_t1_count + 1):
        dst.write(f"{i}|{row}")
os.remove(os.path.join(OUT, "rent_new.tmp"))

# T2 changes in CEO Excel: some clients changed phone number, some women changed surname
t2_clients = [dict(c) for c in clients]
for c in t2_clients[: len(t1_clients)]:
    if random.random() < 0.03:
        c["phone"] = str(random.randint(500000000, 899999999))
    if c["gender"] == "female" and random.random() < 0.02:
        c["surname"] = random.choice(SURNAMES)[1]

# ---------- write snapshots ----------
services_t2 = services_t1 + services_new

for snapshot, t in (("T1", 1), ("T2", 2)):
    folder = os.path.join(OUT, snapshot)
    write_bulk(os.path.join(folder, "location.bulk"), locations)
    write_bulk(os.path.join(folder, "employee.bulk"),
               [[e["id"], e["name"], e["surname"], e[f"loc_t{t}"]] for e in employees[: t1_employee_count if t == 1 else None]])
    write_bulk(os.path.join(folder, "car.bulk"),
               [[c["plate"], c[f"loc_t{t}"], c["brand"], c["model"], c["color"], c[f"km_t{t}"], f"{c[f'price_t{t}']}.00",
                 c["year"], c["fuel"], c["type"]] for c in cars if t == 2 or c["start"] < CUTOFF])
    write_bulk(os.path.join(folder, "service.bulk"),
               [[i] + s for i, s in enumerate(services_t1 if t == 1 else services_t2, start=1)])
    write_excel(os.path.join(folder, "clients.xlsx"), t1_clients if t == 1 else t2_clients,
                CUTOFF - timedelta(days=1) if t == 1 else END)

print(f"T1: {rents_t1_count} rents, {len(services_t1)} services, {len(t1_clients)} clients")
print(f"T2: {rents_count} rents, {len(services_t2)} services, {len(clients)} clients, {len(cars)} cars")
