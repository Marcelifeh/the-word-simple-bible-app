import os, sqlite3, json

# Hardcode the relative path if .env isn't helping us find the local sqlite
db_url = os.path.join('server', 'app', 'bible.db')

if not os.path.exists(db_url):
    print("Local SQLite missing at:", db_url)
    import sys; sys.exit(1)

conn = sqlite3.connect(db_url)
cursor = conn.cursor()

print("Commentary Stats")
print("Style | Has Payload | Count")
try:
    cursor.execute('SELECT style, CASE WHEN payload_json IS NOT NULL AND payload_json != "" THEN "Yes" ELSE "No" END, COUNT(*) FROM commentaries GROUP BY 1, 2')
    results = cursor.fetchall()
    for row in results:
        print(f"{row[0]} | {row[1]} | {row[2]}")
except Exception as e:
    print("Comm Error:", e)

print("\nVerse Counts")
for trans in ["kjv", "web"]:
    try:
        cursor.execute("SELECT COUNT(*) FROM verses WHERE translation_id = ?", (trans,))
        count = cursor.fetchone()[0]
        print(f"{trans.upper()}: {count}")
    except Exception as e:
        print(f"{trans.upper()}: 0")
conn.close()
