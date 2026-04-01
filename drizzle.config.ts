// drizzle.config.ts
import type { Config } from 'drizzle-kit';

export default {
  schema: './src/db/schema.ts',
  out: './drizzle',                    // 迁移文件输出目录
  dialect: 'sqlite',                   // 必须指定
  driver: 'better-sqlite',             // 对应 better-sqlite3
  dbCredentials: {
    url: './data/db.sqlite',           // 构建时临时路径，运行时会被 volume 覆盖
  },
} satisfies Config;