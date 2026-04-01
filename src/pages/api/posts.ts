import { db, posts } from '../../db/index.js';
import type { APIRoute } from 'astro';

export const GET: APIRoute = async () => {
  const allPosts = await db.select().from(posts);
  return new Response(JSON.stringify(allPosts), {
    headers: { 'Content-Type': 'application/json' }
  });
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();
    const { slug, title, description, content, author } = body;

    if (!slug || !title || !content) {
      return new Response('Missing required fields', { status: 400 });
    }

    await db.insert(posts).values({
      slug,
      title,
      description,
      content,           // 可以存 Markdown 或转成 HTML
      author: author || '匿名',
    });

    return new Response(JSON.stringify({ success: true, slug }), { 
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response('Failed to create post', { status: 500 });
  }
};