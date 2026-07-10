# Third-party notices

AI Gateway Kit does not vendor the following applications. Docker pulls them directly from their publishers using the image references in `.env`. Their licenses, trademarks, support policies, and service terms remain independent from this repository's Apache-2.0 license.

## Sub2API

- Source: <https://github.com/Wei-Shaw/sub2api>
- Reviewed image: `weishaw/sub2api:0.1.151`
- Reviewed source revision: `deff3123ded1d14e51df1fd1286e3d43ed9ec9bd`
- License file at that revision: GNU Lesser General Public License v3.0

The upstream README also contains a no-commercial-authorization statement. Operators should clarify the resulting commercial-use boundary with upstream before relying on commercial deployment.

## PostgreSQL

- Source: <https://www.postgresql.org/>
- Reviewed image: `postgres:18.4-alpine3.24`
- License: PostgreSQL License

## Redis Open Source

- Source: <https://github.com/redis/redis>
- Reviewed image: `redis:8.8.0-alpine3.23`
- License options for Redis 8+: RSALv2, SSPLv1, or AGPLv3, at the user's option
- License overview: <https://redis.io/legal/licenses/>

This kit treats Redis as an unmodified, separately distributed network service. Operators remain responsible for selecting and complying with an applicable Redis license.

## Caddy

- Source: <https://github.com/caddyserver/caddy>
- Reviewed image: `caddy:2.11.4-alpine`
- License: Apache License 2.0

## Provider names and trademarks

OpenAI, ChatGPT, Anthropic, Claude, Google, Gemini, Docker, PostgreSQL, Redis, Caddy, and other names are trademarks of their respective owners. References identify interoperability or upstream components and do not imply affiliation or endorsement.
