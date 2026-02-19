const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database path from .env (default: ./data/plant-disease.db)
const dbPath = path.resolve(__dirname, 'data', 'plant-disease.db');

console.log(`Connecting to database at: ${dbPath}`);

const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
  if (err) {
    console.error('Error opening database:', err.message);
    process.exit(1);
  }
});

db.serialize(() => {
  db.all('SELECT id, email, fullName, createdAt, updatedAt FROM user', [], (err, rows) => {
    if (err) {
      console.error('Error querying database:', err.message);
      db.close();
      return;
    }

    if (rows.length === 0) {
      console.log('No users found in the database.');
    } else {
      console.log('User Registration Details:');
      console.table(rows);
    }

    db.close();
  });
});
