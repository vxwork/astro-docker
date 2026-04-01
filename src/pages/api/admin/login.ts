// src/pages/api/admin/login.ts
import type { APIRoute } from 'astro';

export const POST: APIRoute = async ({ request, cookies }) => {
  try {
    const formData = await request.formData();
    const username = formData.get('username')?.toString().trim();
    const password = formData.get('password')?.toString().trim();

    const correctUsername = import.meta.env.ADMIN_USERNAME || 'admin';
    const correctPassword = import.meta.env.ADMIN_PASSWORD || 'admin123';

    console.log(`[Login Attempt] Username: ${username}, Expected: ${correctUsername}`);

    if (username === correctUsername && password === correctPassword) {
      cookies.set('admin_logged_in', 'true', {
        path: '/admin',
        maxAge: 60 * 60 * 24 * 7,   // 7天
        httpOnly: true,
        secure: false,
        sameSite: 'lax'
      });

      console.log('✅ Login successful');
      return Response.redirect('/admin', 302);
    }

    console.log('❌ Login failed: wrong credentials');
    return new Response(`
      <h2 style="color: red; text-align: center; margin-top: 80px; font-family: system-ui;">
        用户名或密码错误<br><br>
        <a href="/admin" style="color: blue;">← 返回重新登录</a>
      </h2>
    `, {
      status: 401,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });

  } catch (error) {
    console.error('Login error:', error);
    return new Response('服务器错误，请稍后重试', { status: 500 });
  }
};