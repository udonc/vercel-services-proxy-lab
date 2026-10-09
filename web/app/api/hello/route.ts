export function GET(request: Request): Response {
  return Response.json({
    ok: true,
    path: new URL(request.url).pathname,
    fromProxy: request.headers.get('x-from-proxy'),
  });
}
