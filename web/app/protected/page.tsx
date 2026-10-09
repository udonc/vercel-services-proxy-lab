import { cookies, headers } from 'next/headers';

export const dynamic = 'force-dynamic';

export default async function ProtectedPage() {
  const cookieStore = await cookies();
  const headerStore = await headers();
  return (
    <main>
      <h1>web: /protected</h1>
      <p>session cookie: {cookieStore.get('session') ? 'present' : 'absent'}</p>
      <p>x-from-proxy request header: {headerStore.get('x-from-proxy') ?? 'absent'}</p>
    </main>
  );
}
