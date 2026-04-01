// src/pages/api/admin/login.ts
import type { APIRoute } from 'astro';

export const POST: APIRoute = async ({ request, cookies }) => {
  try {
    const formData = await request.formData();
    const username = formData.get('username')?.toString().trim();
    const password = formData.get('password')?.toString().trim();

    // 从环境变量读取用户名和密码（推荐）
    const correctUsername = import.meta.env.ADMIN_USERNAME || 'admin';
    const correctPassword = import.meta.env.ADMIN_PASSWORD || 'admin123';

    if (username === correctUsername && password === correctPassword) {
      cookies.set('admin_logged_in', 'true', {
        path: '/admin',
        maxAge: 60 * 60 * 24,     // 24小时有效
        httpOnly: true,
        secure: false,            // 本地测试用 false，生产 HTTPS 环境改成 true
        sameSite: 'lax'
      });

      return Response.redirect('/admin', 302);
    }

    // 登录失败
    return new Response(`
      <h2 style="color:red; text-align:center; margin-top:50px;">
        用户名或密码错误<br><br>
        <a href="/admin">返回重新登录</a>
      </h2>
    `, { 
      status: 401,
      headers: { 'Content-Type': 'text/html' }
    });

  } catch (error) {
    console.error('Login error:', error);
    return new Response('登录失败，请稍后重试', { status: 500 });
  }
};