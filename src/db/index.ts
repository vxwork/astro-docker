// src/db/index.ts - 纯 SQL 简化版
import Database from 'better-sqlite3';

const dbPath = import.meta.env.PROD 
  ? '/app/data/db.sqlite' 
  : './data/db.sqlite';

const sqlite = new Database(dbPath);

// 导出 db 实例
export const db = sqlite;

// 自动创建表
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

console.log('✅ SQLite 数据库已就绪（纯 SQL 模式）');

// 导出常用方法，方便页面和 API 使用
export const getAllPosts = () => {
  return db.prepare('SELECT * FROM posts ORDER BY publishedAt DESC').all();
};

export const getPostBySlug = (slug: string) => {
  return db.prepare('SELECT * FROM posts WHERE slug = ?').get(slug);
};

export const createPost = (post: { slug: string; title: string; description?: string; content: string; author?: string }) => {
  const stmt = db.prepare(`
    INSERT INTO posts (slug, title, description, content, author)
    VALUES (?, ?, ?, ?, ?)
  `);
  return stmt.run(post.slug, post.title, post.description || null, post.content, post.author || '匿名');
};