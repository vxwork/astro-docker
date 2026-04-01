// src/pages/api/admin/login.ts
import type { APIRoute } from 'astro';

export const POST: APIRoute = async ({ request, cookies }) => {
  try {
    const formData = await request.formData();
    const username = (formData.get('username') || '').toString().trim();
    const password = (formData.get('password') || '').toString().trim();

    console.log(`[Login Attempt] 输入用户名: "${username}", 输入密码: "${password}"`);

    // 临时固定账号密码（便于调试）
    const correctUsername = 'admin';
    const correctPassword = 'admin123';

    if (username === correctUsername && password === correctPassword) {
      cookies.set('admin_logged_in', 'true', {
        path: '/admin',
        maxAge: 60 * 60 * 24 * 7,
        httpOnly: true,
        secure: false,
        sameSite: 'lax'
      });

      console.log('✅ 登录成功！');
      return Response.redirect('/admin', 302);
    }

    console.log('❌ 登录失败：用户名或密码错误');
    return new Response(`
      <h2 style="color: red; text-align: center; margin-top: 80px; font-family: system-ui;">
        用户名或密码错误<br><br>
        <a href="/admin" style="color: blue; text-decoration: underline;">← 返回重新登录</a>
      </h2>
    `, {
      status: 401,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });

  } catch (error) {
    console.error('登录异常:', error);
    return new Response('服务器内部错误', { status: 500 });
  }
};