import sqlite3, json

DB="data/history.db"

def save_history(report):
    conn=sqlite3.connect(DB)
    cur=conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS scans (id INTEGER PRIMARY KEY, data TEXT)")
    cur.execute("INSERT INTO scans(data) VALUES (?)",(json.dumps(report),))
    conn.commit()
    conn.close()
