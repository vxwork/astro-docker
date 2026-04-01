import { drizzle } from 'drizzle-orm/better-sqlite3';
import Database from 'better-sqlite3';
import * as schema from './schema.js';

const dbPath = import.meta.env.PROD 
  ? '/app/data/db.sqlite' 
  : './data/db.sqlite';

const sqlite = new Database(dbPath);
export const db = drizzle(sqlite, { schema });

// ============== 运行时自动创建表（最简化方式） ==============
sqlite.exec(`
  CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    slug TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    description TEXT,
    content TEXT NOT NULL,
    author TEXT DEFAULT '匿名',
    publishedAt INTEGER DEFAULT (unixepoch() * 1000)
  );
`);

console.log('✅ SQLite 数据库已就绪，表已自动创建');