import { drizzle } from 'drizzle-orm/better-sqlite3';
import Database from 'better-sqlite3';
import * as schema from './schema.js';

// 数据库路径（Docker 中挂载到 /app/data）
const dbPath = import.meta.env.PROD 
  ? '/app/data/db.sqlite' 
  : './data/db.sqlite';

const sqlite = new Database(dbPath);
export const db = drizzle(sqlite, { schema });

// 自动创建表（第一次启动时执行）
import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
migrate(db, { migrationsFolder: './drizzle' });