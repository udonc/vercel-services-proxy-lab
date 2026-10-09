import { next } from '@vercel/functions';

const hasSessionCookie = (request: Request): boolean =>
  /(?:^|;\s*)session=/.test(request.headers.get('cookie') ?? '');

export default function proxy(request: Request): Response {
  const { pathname } = new URL(request.url);

  if (pathname === '/from-proxy') {
    return new Response('hi from top-level proxy', {
      headers: { 'content-type': 'text/plain', 'x-proxy-ran': '1' },
    });
  }

  if (pathname === '/protected' && !hasSessionCookie(request)) {
    return new Response(null, {
      status: 302,
      headers: { location: '/login', 'x-proxy-ran': '1' },
    });
  }

  // The Node.js runtime does not synthesize the fall-through for an empty
  // return (unlike the edge runtime), so `next()` is explicit.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-from-proxy', '1');
  return next({
    request: { headers: requestHeaders },
    headers: {
      'x-proxy-ran': '1',
      'set-cookie': 'proxy-seen=1; Path=/; HttpOnly',
    },
  });
}
