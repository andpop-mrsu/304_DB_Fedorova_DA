#!/usr/bin/env python3
"""Генерация SQL-скрипта db_init.sql для создания и заполнения БД movies_rating.db.

Исходные текстовые файлы (movies.csv, ratings.csv, tags.csv, users.txt)
ожидаются в том же каталоге, что и этот скрипт (Task02).
"""

import csv
import os
import re
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SQL_FILE = os.path.join(BASE_DIR, "db_init.sql")


def esc(value: str) -> str:
    """Экранирование одинарных кавычек для SQL."""
    return str(value).replace("'", "''")


def parse_title_year(raw_title: str):
    """Разделяет 'Toy Story (1995)' на ('Toy Story', 1995)."""
    m = re.match(r"^(.*?)\s*\((\d{4})\)\s*$", raw_title)
    if m:
        return m.group(1).strip(), int(m.group(2))
    return raw_title.strip(), None


def main():
    with open(SQL_FILE, "w", encoding="utf-8") as out:
        out.write("PRAGMA foreign_keys = OFF;\n")
        out.write("BEGIN TRANSACTION;\n\n")

        # --- DROP TABLE (в порядке, обратном зависимостям) ---
        for t in ("tags", "ratings", "movies", "users"):
            out.write(f"DROP TABLE IF EXISTS {t};\n")
        out.write("\n")

        # --- CREATE TABLE ---
        out.write("""CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);
""")
        out.write("""CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER,
    genres TEXT
);
""")
        out.write("""CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);
""")
        out.write("""CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    movie_id INTEGER,
    tag TEXT,
    timestamp INTEGER
);
""")
        out.write("\n")

        # --- INSERT users ---
        users_path = os.path.join(BASE_DIR, "users.txt")
        with open(users_path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                parts = line.split("|")
                if len(parts) < 6:
                    continue
                uid, name, email, gender, reg, occ = parts[:6]
                out.write(
                    f"INSERT INTO users VALUES "
                    f"({int(uid)}, '{esc(name)}', '{esc(email)}', "
                    f"'{esc(gender)}', '{esc(reg)}', '{esc(occ)}');\n"
                )
        out.write("\n")

        # --- INSERT movies ---
        movies_path = os.path.join(BASE_DIR, "movies.csv")
        with open(movies_path, encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            for row in reader:
                mid = int(row["movieId"])
                title, year = parse_title_year(row["title"])
                year_sql = year if year is not None else "NULL"
                out.write(
                    f"INSERT INTO movies VALUES "
                    f"({mid}, '{esc(title)}', {year_sql}, '{esc(row['genres'])}');\n"
                )
        out.write("\n")

        # --- INSERT ratings ---
        ratings_path = os.path.join(BASE_DIR, "ratings.csv")
        with open(ratings_path, encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            for row in reader:
                out.write(
                    f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) "
                    f"VALUES ({int(row['userId'])}, {int(row['movieId'])}, "
                    f"{float(row['rating'])}, {int(row['timestamp'])});\n"
                )
        out.write("\n")

        # --- INSERT tags ---
        tags_path = os.path.join(BASE_DIR, "tags.csv")
        with open(tags_path, encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            for row in reader:
                out.write(
                    f"INSERT INTO tags (user_id, movie_id, tag, timestamp) "
                    f"VALUES ({int(row['userId'])}, {int(row['movieId'])}, "
                    f"'{esc(row['tag'])}', {int(row['timestamp'])});\n"
                )

        out.write("\nCOMMIT;\n")

    print(f"[OK] Generated {SQL_FILE}", file=sys.stderr)


if __name__ == "__main__":
    main()