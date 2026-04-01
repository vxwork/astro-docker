import type { APIRoute } from 'astro';
import { createPost } from '../../db/index.js';

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();
    const { slug, title, description, content, author } = body;

    if (!slug || !title || !content) {
      return new Response('Missing required fields: slug, title, content', { status: 400 });
    }

    createPost({ slug, title, description, content, author });

    return new Response(JSON.stringify({ 
      success: true, 
      message: '文章创建成功',
      slug 
    }), { 
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Create post error:', error);
    return new Response('Failed to create post', { status: 500 });
  }
};