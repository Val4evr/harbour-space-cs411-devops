# Reflection — introduction-to-builds

## What did I do?

I started from the provided `main.go`, a small Go HTTP service that marshals a
`Simple{Name, Description, Url}` struct to JSON and serves it on `:4444`. I built it with
`go build main.go`, which produced a `./main` binary in `~/app`, then ran `./main` — the
terminal printed `Server started on port 4444` and stayed in the foreground. From a second
terminal I hit it with `curl localhost:4444` and got back
`{"Name":"Hello","Description":"World","Url":"localhost:4444"}`, and the lab's App tab showed
the same payload. Once it was working I committed `main.go` to the repo's `main` branch and
pushed it to GitHub.

## What was most surprising?

I was using Claude to do most of this for me, and tried giving it a Pangram API key and asking
it to iterate until it could produce a text that was not detectable as AI. This surprisingly
failed. Maybe adopting Pangram to catch AI-written REFLECTION.mds (like the first part of this
one, to be honest) is a good idea.

## What's still unclear?

All clear, nothing much to say. I guess I'm curious how cross-platform builds are handled when
cross-compilation is not feasible — but this is more of a "pipeline with multiple build machines
running different OSes" kind of question.

## Stretch tasks

I built all three artifacts in `~/app`:
- **arm64 cross-compile** (`main-arm64`): `file` reports `ARM aarch64, statically linked` vs. the
  native `x86-64, dynamically linked` — the architecture changed and so did the linkage, because
  cross-builds disable CGO and force a static link.
- **Stripped** (`main-stripped`): `-ldflags='-s -w'` took it from 7,281,464 B to 4,964,612 B
  (~32% smaller); the trade-off is no symbols/debug info for `gdb` or stack traces.
- **Ruby/Sinatra** (`app.rb`): same JSON shape on `:4444`, run with `ruby-full` plus the
  `sinatra`/`webrick` gems. One thing the Go binary needs at runtime: a compatible `libc.so.6`
  (only for the dynamic build). One thing the Ruby script needs: the Ruby interpreter plus the
  `sinatra` gem installed on the machine.
