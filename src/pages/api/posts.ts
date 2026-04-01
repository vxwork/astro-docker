import type { APIRoute } from 'astro';
import { createPost } from '../../db/index.js';

export const POST: APIRoute = async ({ request }) => {
  try {
    let body;

    // 支持 FormData（表单提交）和 JSON
    const contentType = request.headers.get('content-type') || '';
    if (contentType.includes('application/json')) {
      body = await request.json();
    } else {
      const formData = await request.formData();
      body = {
        slug: formData.get('slug'),
        title: formData.get('title'),
        content: formData.get('content'),
        author: formData.get('author') || '匿名',
      };
    }

    const { slug, title, content, author, description } = body;

    if (!slug || !title || !content) {
      return new Response('缺少必要字段', { status: 400 });
    }

    createPost({ slug, title, description, content, author });

    return Response.redirect('/admin', 302);
  } catch (error) {
    console.error(error);
    return new Response('发布失败', { status: 500 });
  }
};