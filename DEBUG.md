# DEBUG.md — introduction-to-builds

## Scenario

`./main` builds and runs fine on the playground's `jenkins` machine (glibc 2.39),
but on a fresh Ubuntu 18.04 VM it dies immediately with:

```
./main: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.34' not found (required by ./main)
```

## Two ranked hypotheses

1. **(Most likely) The binary is dynamically linked against a newer glibc than the target provides.**
   The build host ships glibc 2.39 and Go's default build keeps CGO enabled (a C toolchain
   is present), so `main` links `libc.so.6` *dynamically* and records a requirement on the
   symbol version `GLIBC_2.34`. Ubuntu 18.04 ships glibc 2.27, which has no `GLIBC_2.34`
   version node, so the dynamic loader can't resolve the symbol. Plausible because the error
   names exactly this — `libc.so.6`, `version GLIBC_2.34 not found` — which is the textbook
   signature of a forward glibc-version gap.

2. **(Less likely) libc is not the only too-new shared library the binary needs.**
   A CGO/stdlib path (the `net` cgo DNS resolver, `os/user`) can pull in other system
   libraries (`libpthread`, `libnss_*`) that carry their own version floors, so even after
   libc is satisfied the binary could still fail on the old target. Plausible because
   "runs on the build box, breaks on the old box" is the generic symptom of *any* too-new
   dynamic dependency, not only libc.

## One verification step per hypothesis

1. On the **build** host, list the highest glibc symbol version the binary demands:
   ```
   objdump -T ./main | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1
   ```
   If this prints `GLIBC_2.34` (or higher), H1 is confirmed — the binary's floor sits
   above the target's 2.27.

2. On the **customer** VM, confirm what it actually provides and whether libc is the only gap:
   ```
   ldd --version | head -1     # -> glibc 2.27 on Ubuntu 18.04
   ldd ./main                  # every dynamic dep; "=> not found" lines flag any others
   ```
   If `ldd ./main` shows only `libc.so.6` as the offender, H1 alone explains it; if other
   libraries also report missing versions, H2 is contributing too.

## Fix (minimal)

Produce a binary with **no glibc dependency** by disabling CGO, so Go uses its pure-Go
runtime and links statically:

```
CGO_ENABLED=0 go build -o main main.go
file ./main   # -> "statically linked" — no interpreter, no libc.so.6 requirement
```

The resulting binary carries no `GLIBC_*` requirements at all and runs unchanged on
Ubuntu 18.04 (or even a `scratch` container). If CGO is genuinely required, the equivalent
fix is to build against the *oldest* target glibc — e.g. compile inside an Ubuntu 18.04
container — rather than on the 2.39 host.

## Underlying lesson

glibc is backward- but **not** forward-compatible, so a dynamically-linked binary is only
as portable as the *oldest* glibc it will ever run against — build static (or against the
lowest target glibc) whenever you don't control the deployment machine.
