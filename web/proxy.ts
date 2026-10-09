import { NextResponse, type NextRequest } from 'next/server';

export function proxy(request: NextRequest): NextResponse {
  if (request.nextUrl.pathname === '/web-proxy-check') {
    return NextResponse.json(
      { ranIn: 'next-proxy', fromProxy: request.headers.get('x-from-proxy') },
      { headers: { 'x-next-proxy-ran': '1' } },
    );
  }
  const response = NextResponse.next();
  response.headers.set('x-next-proxy-ran', '1');
  return response;
}
