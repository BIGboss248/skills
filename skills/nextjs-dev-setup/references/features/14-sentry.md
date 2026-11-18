# N14 — Sentry Accountability

**Category:** Foundation · **Default:** on · **Depends on:** N2

Sentry maintains a setup prompt that it keeps aligned with its own SDK, dashboard,
and current recommendations. This feature exists to get that prompt into the
conversation and follow it, instead of restating Sentry's instructions here, where
they would go stale within a release or two.

The skill owns the handoff. Sentry owns the instructions.

## Enable when

The client wants error monitoring in production and can reach a Sentry account.
When they have no account and do not want one, record `[SKIPPED]`.

## Steps

1. Check whether the project already talks to Sentry — a dependency, a DSN, or an
   initializer file. If it does, report `[UNTOUCHED]` and stop: re-running a setup
   prompt over a working integration breaks it.
2. Ask the client to open Sentry and create a **new project** for this app.
3. Ask them to copy the setup prompt Sentry gives them for a coding agent, and
   paste it into this chat unedited.
4. Follow that prompt. It is the source of truth for packages, file names,
   configuration, and verification. Where it disagrees with anything else in this
   skill or with your own memory of the SDK, it wins.
5. If no prompt arrives — no account, a handoff page that refuses the code, or a
   prompt the client cannot find — record `[BLOCKED]` with the reason. Do not
   reconstruct a setup from memory, and never invent a DSN.
6. Report which files the prompt changed, whether the client saw the test error
   themselves, and anything the prompt asked for that you could not do.

## Acceptance

- [ ] The client created the project, or the feature is `[SKIPPED]`/`[BLOCKED]`
      with a reason.
- [ ] The implementation came from the pasted prompt, not from this file.
- [ ] A real error from the running app was confirmed in Sentry, and the client
      saw its title and URL.
- [ ] No auth token, secret, or `.env.local` value was committed.
- [ ] Build-time values were checked against the build that actually ships them.

## Notes

- Ask about network filtering when the client mentions a proxy, a firewall, or
  ad-blockers: Sentry's ingest domains are commonly blocked, and the prompt
  describes the supported way to route events through the app. Do not invent a
  workaround; ask for the prompt's answer.
- Leave no Sentry code, template, or environment key in this skill. Anything
  concrete here becomes a second, older copy of Sentry's own documentation.
