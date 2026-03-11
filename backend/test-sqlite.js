const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database(':memory:');
db.serialize(() => {
  db.run("CREATE TABLE foo (bar TEXT)");
  db.run("INSERT INTO foo VALUES ('hello')");
  db.all("SELECT * FROM foo", (err, rows) => {
    if (err) {
      console.error(err);
    } else {
      console.log('SQLite works:', rows);
    }
    db.close();
  });
});
