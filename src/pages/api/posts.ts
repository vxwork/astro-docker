import type { APIRoute } from 'astro';
import { createPost, db } from '../../db/index.js';
import fs from 'fs';
import path from 'path';

const UPLOAD_DIR = '/app/public/uploads';

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();
    
    const title = formData.get('title') as string;
    const slug = formData.get('slug') as string;
    const content = formData.get('content') as string;
    const author = formData.get('author') as string || 'Grok';
    const originalSlug = formData.get('originalSlug') as string;
    const image = formData.get('image') as File;

    if (!slug || !title || !content) {
      return new Response('缺少必要字段', { status: 400 });
    }

    // 处理图片上传
    let imageUrl = '';
    if (image && image.size > 0) {
      const bytes = await image.arrayBuffer();
      const buffer = Buffer.from(bytes);
      
      const ext = path.extname(image.name);
      const filename = `${Date.now()}${ext}`;
      const filepath = path.join(UPLOAD_DIR, filename);

      // 确保目录存在
      if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

      fs.writeFileSync(filepath, buffer);
      imageUrl = `/uploads/${filename}`;
      
      // 可选：在 content 中自动插入图片
      // content = `![${image.name}](${imageUrl})\n\n` + content;
    }

    // 创建或更新文章
    createPost({ 
      slug, 
      title, 
      content: content + (imageUrl ? `\n\n![uploaded](${imageUrl})` : ''), 
      author 
    });

    return Response.redirect('/admin', 302);
  } catch (error) {
    console.error('发布失败:', error);
    return new Response('发布失败: ' + error.message, { status: 500 });
  }
};