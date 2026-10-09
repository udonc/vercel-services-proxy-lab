# vercel-services-proxy-lab

Reproduction and verification repo for one question about [Vercel Services](https://vercel.com/docs/services):

> Does a **top-level Routing Middleware** configured through `vercel.json` `proxy.entrypoint` run on a Services deployment, given that [middleware inside a service is documented as unsupported](https://vercel.com/docs/build-output-api/services)?

Related upstream reports: [vercel/vercel#16915](https://github.com/vercel/vercel/issues/16915), [vercel/vercel#16296](https://github.com/vercel/vercel/issues/16296).

## Layout

| Path | Role |
| --- | --- |
| `vercel.json` | One service (`web`, Next.js) behind a catch-all rewrite, plus `proxy.entrypoint` pointing at `routing-proxy.ts` |
| `routing-proxy.ts` | Top-level Routing Middleware. Answers `/from-proxy` directly, redirects `/protected` to `/login` without a `session` cookie, otherwise falls through with `x-proxy-ran: 1`, a `Set-Cookie`, and an `x-from-proxy` request header for the service. Not named `proxy.ts` on purpose; see Results |
| `web/` | Minimal Next.js 16 app: `/` (static), `/protected` (dynamic, echoes the cookie), `/login`, `/api/hello` |
| `check.sh` | Request matrix that prints the status and the headers identifying which layer handled each path |

## Variants

| Branch | Top-level `proxy.entrypoint` | In-service `web/proxy.ts` (Next.js Proxy) |
| --- | --- | --- |
| `main` | yes | no |
| `in-service-only` | no | yes |
| `both` | yes | yes |

The in-service proxy answers `/web-proxy-check` and adds `x-next-proxy-ran: 1`; a 404 on that path means the Next.js proxy was built but never wired, which is the symptom reported in #16915.

## Checking a deployment

```bash
./check.sh https://<deployment>.vercel.app            # preview (protected): uses `vercel curl`
./check.sh https://<deployment>.vercel.app curl       # unprotected production URL
```

## Results (2026-10-09)

Short version: **both layers run.** The top-level `proxy.entrypoint` runs ahead of the service, and, contrary to the Build Output API constraint ("Middleware is not supported inside a service", page dated 2026-09-15), the Next.js `proxy.ts` inside the service also runs.

Environment: deployed with Vercel CLI 62.4.0 (`vercel deploy`, no `--prebuilt`); the build containers ran Vercel CLI 62.1.0 (A, B) and 62.7.0 (C); Next.js 16.4.0; project framework preset `services`, root directory unset; hobby team.

| Request | A `main` (top-level only) | B `in-service-only` | C `both` |
| --- | --- | --- | --- |
| `GET /` | 200, `x-proxy-ran`, `Set-Cookie` (also on cache HIT) | 200, `x-next-proxy-ran` (prerendered page) | 200, both headers |
| `GET /from-proxy` | 200 `hi from top-level proxy` | 404 (Next.js not-found page, `x-next-proxy-ran`) | 200 from the top-level proxy, no `x-next-proxy-ran` |
| `GET /protected` without cookie | 302 → `/login` | 200 (page renders) | 302 → `/login` |
| `GET /protected` with `session=1` | 200, `x-proxy-ran`; page renders `x-from-proxy request header: 1` | 200, `x-next-proxy-ran`; page renders `x-from-proxy request header: absent` | 200, both headers; page renders `x-from-proxy request header: 1` |
| `GET /api/hello` | 200, `fromProxy: "1"` | 200, `fromProxy: null` | 200, `fromProxy: "1"` |
| `GET /web-proxy-check` | 404 (no Next.js proxy) | 200 `{"ranIn":"next-proxy"}` | 200 `{"ranIn":"next-proxy","fromProxy":"1"}` |

Deployments (preview URLs are behind Vercel Authentication; the production URL is public):

| Variant | Deployment | Build output |
| --- | --- | --- |
| A | `dpl_BiR3RhjNwJWs2ANs6BiRQzqb6EUU` (vercel-services-proxy-hljo0knva-udon.vercel.app) | `out/routing-proxy`, `out/services/web/*` |
| B | `dpl_J91gE7gka3si9Vvm5Ja7VH9tgCHR` (vercel-services-proxy-bqhgli0cr-udon.vercel.app) | `out/services/web/_middleware` |
| C | `dpl_6qmurn312egWjiPRzDA2mMz1TwQx` (vercel-services-proxy-6laogjlvl-udon.vercel.app) | `out/routing-proxy`, `out/services/web/_middleware` |
| C, production | `dpl_s5EpFNgXr6HS1Sk2BXKgSdwmtTJJ` → https://vercel-services-proxy-lab.vercel.app | same as C |

Observations:

- Order is top-level proxy first, then the Next.js proxy, then the route. In C, `/from-proxy` and the `/protected` redirect never reach the Next.js proxy.
- `next({ request: { headers } })` from `@vercel/functions` works across the service boundary: the `x-from-proxy` header set by the top-level proxy is visible to the Next.js proxy, to route handlers, and to `headers()` in a dynamic page.
- Response headers and `Set-Cookie` from the top-level proxy are applied to passthrough responses, including CDN cache hits.
- Naming the top-level entrypoint `proxy.ts` at the repository root broke the build: the Next.js service build (`next build` in `web/`) compiled `./proxy.ts` as the Next.js Proxy and failed with `Module not found: Can't resolve '@vercel/functions'` (`dpl_81mxRZFijTipUYeYBt5G1iDSNHcK`). Local `vercel build` 62.4.0 and a local `next build` with `turbopack.root` pointed at the repository root did not reproduce it. Any other file name avoids the collision; this repo uses `routing-proxy.ts`.

Not covered: more than one service, service bindings, the Edge runtime, Git-integration builds, `--prebuilt` deploys.
