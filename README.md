# vercel-services-proxy-lab

Reproduction and verification repo for one question about [Vercel Services](https://vercel.com/docs/services):

> Does a **top-level Routing Middleware** configured through `vercel.json` `proxy.entrypoint` run on a Services deployment, given that [middleware inside a service is documented as unsupported](https://vercel.com/docs/build-output-api/services)?

Related upstream reports: [vercel/vercel#16915](https://github.com/vercel/vercel/issues/16915), [vercel/vercel#16296](https://github.com/vercel/vercel/issues/16296).

## Layout

| Path | Role |
| --- | --- |
| `vercel.json` | One service (`web`, Next.js) behind a catch-all rewrite, plus `proxy.entrypoint` pointing at `proxy.ts` |
| `proxy.ts` | Top-level Routing Middleware. Answers `/from-proxy` directly, redirects `/protected` to `/login` without a `session` cookie, otherwise falls through with `x-proxy-ran: 1` and a `Set-Cookie` |
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

## Results

Pending.
