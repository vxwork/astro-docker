// src/db/index.ts
import { drizzle } from 'drizzle-orm/better-sqlite3';
import Database from 'better-sqlite3';
import * as schema from './schema.js';   // 导入 schema 中的 posts

const dbPath = import.meta.env.PROD 
  ? '/app/data/db.sqlite' 
  : './data/db.sqlite';

const sqlite = new Database(dbPath);
export const db = drizzle(sqlite, { schema });

// 导出 posts 表，供 API 和页面使用
export const { posts } = schema;

// 运行时自动创建表（简化版，不依赖 drizzle-kit）
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

console.log('✅ SQLite 数据库已就绪，posts 表已自动创建');