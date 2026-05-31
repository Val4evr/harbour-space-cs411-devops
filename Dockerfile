# Single-stage image. Base pinned by DIGEST (stretch task): a tag like `golang:1.24`
# is mutable — the same tag can later point at different bytes — whereas the digest is
# content-addressed, so this FROM always resolves to the exact image we tested against.
# This is the multi-arch manifest-index digest, so Docker still auto-selects the right
# architecture at pull time. Tradeoff: bumping the Go version means re-resolving the
# digest by hand (e.g. `docker buildx imagetools inspect golang:1.25`).
FROM golang:1.24@sha256:d2d2bc1c84f7e60d7d2438a3836ae7d0c847f4888464e7ec9ba3a1339a1ee804

# Everything lives under /app, so the built binary is /app/main.
WORKDIR /app

# The repo is a single-file Go program at the root (no go.mod), the same way the
# earlier challenges built it: `go build -o main main.go`.
COPY main.go .

RUN go build -o main main.go

# Documents the port the app serves on; the actual mapping happens at `docker run -p`.
EXPOSE 4444

CMD ["./main"]
