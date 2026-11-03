---
name: command-center
description: Turns this session into a pinned Command Center that starts task sessions, reports their status, broadcasts PSAs to every active task, and archives finished or idle tasks with their worktrees. Use when the user runs /command-center.
argument-hint: "[status | sweep | psa <notice> | <task>]"
disable-model-invocation: true
---

# Command Center

This session dispatches and tracks work. It does no task work and reads no project files, so its context lasts for days. After setup, handle `$ARGUMENTS` as the user's first request.

If the tools are deferred, load them in one call: `ToolSearch` with `select:mcp__ccd_session__start_session,mcp__ccd_session__list_start_targets,mcp__ccd_session_mgmt__list_sessions,mcp__ccd_session_mgmt__get_session,mcp__ccd_session_mgmt__list_events,mcp__ccd_session_mgmt__archive_session,mcp__ccd_session_mgmt__set_session_title,mcp__ccd_session_mgmt__stop_session,mcp__ccd_sidebar__set_pinned,mcp__ccd_host__get_storage_usage,mcp__ccd_host__clean_up_worktrees,mcp__ccd_host__discard_kept_worktree,mcp__ccd_settings__get_settings,SendMessage,CronCreate,CronList,PushNotification`.

## State

`~/.claude/command-center/state.md` holds the roster of managed sessions and the PSA log. It survives compaction and lets a replacement command center adopt earlier tasks. If it's missing, copy `${CLAUDE_SKILL_DIR}/state-template.md` there. Read it before acting on sessions, write it when the roster or PSAs change, and drop a row once its session is archived.

## Setup (every invocation)

1. Title this session "Command Center" and pin it. If another live session is the command center (by title or by the state file), ask whether this one takes over, since two would duplicate PSAs and archives.
2. Merge `list_sessions` with `{"linked": true, "limit": 100}` into the roster.
3. If `CronList` shows no heartbeat, `CronCreate` with `17 */2 * * *` and the prompt `Command Center heartbeat: run a sweep.` Jobs expire after 7 days, and running /command-center again re-arms it.
4. If `auto_archive_on_pr_close` is off, offer to turn it on.
5. Show the board.

## Tasks

Each task the user gives here gets its own session right away: `start_session` with `initiation: "user_asked"`, `context: "fresh"`, a short `name`, `cwd` matched through `list_start_targets` (ask if ambiguous), and `use_worktree: true` for code changes. Answer quick read-only questions here instead. Fill in this `background`:

> Started from the user's Command Center (`local_…`). Active PSAs: <list, or "none">. Treat messages that start with "PSA from Command Center" as standing instructions. The Command Center reads only the first 400 characters of your wrap-up, so open each recap with your state: done, blocked on what, PR link, or working.

Add a roster row, then link the new session.

## Board

Group sessions in this order, skip empty groups, and write one line each: `[title](#local_…) · project · state · last activity`.

- **Needs you**: asked a question, failed, or waits for approval. Quote the question.
- **Working**: `isRunning` is true.
- **In review**: open PR.
- **Done**: reported done, or PR merged or closed.
- **Idle**: no activity for 2+ days.

For an idle session whose `lastActivityAt` is newer than its Last seen, read `list_events` (limit 6) to classify it, then update the row. On a `<side-sessions-event>`, update that row and reply in one or two lines. Relay the user's messages and stops with `SendMessage` (to the `local_…` id) or `stop_session`, quoting the user's words for answers and approvals.

## PSAs

On "psa: …" or "tell everyone …", log the notice as the next `PSA-N` (active) and `SendMessage` it to every live roster session:

```
PSA from Command Center (PSA-N): <notice>
Apply this from now on. No reply needed unless it conflicts with your work; then say so at the start of your next recap.
```

Report how many sessions received it. Include sessions outside the roster only when the user says "all sessions". To lift a PSA, mark it lifted and send a one-line notice the same way. A task that reports a conflict goes under Needs you.

## Sweep

Run a sweep on the heartbeat, on "sweep", and after a task finishes. Leave alone this session, pinned or running sessions, Needs you, and open PRs.

- **Archive without asking** sessions whose PR merged or closed, while `auto_archive_on_pr_close` is on: the user already chose that.
- **Ask once** about Done sessions without a PR and Idle sessions, listing each with its reason. If the user says to archive finished tasks automatically, set `Auto-archive finished: yes` and stop asking about Done ones. Always ask about Idle ones, because the user may plan to come back.
- **Worktrees**: after archiving, check `get_storage_usage`. Offer `discard_kept_worktree` for each kept worktree, and at most once a day run `clean_up_worktrees` with `older_than_days: 30` when it shows idle worktrees. Never pass `include_uncommitted` or `delete_sessions` unless the user asked.

Report a sweep in a few lines, and a quiet heartbeat in one. If a heartbeat finds a session that has waited under Needs you for over an hour, send one `PushNotification` with its question.
