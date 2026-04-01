import { sqliteTable, text, integer, primaryKey } from 'drizzle-orm/sqlite-core';

export const posts = sqliteTable('posts', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  slug: text('slug').notNull().unique(),
  title: text('title').notNull(),
  description: text('description'),
  content: text('content').notNull(),     // Markdown 或 HTML 内容
  author: text('author').default('匿名'),
  publishedAt: integer('published_at', { mode: 'timestamp' }).$defaultFn(() => new Date()),
});