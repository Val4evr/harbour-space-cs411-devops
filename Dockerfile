# Simple single-stage image for the core task.
# (Multi-stage / distroless / scratch is a stretch task — kept out of the core on purpose.)
FROM golang:1.24

# Everything lives under /app, so the built binary is /app/main.
WORKDIR /app

# The repo is a single-file Go program at the root (no go.mod), the same way the
# earlier challenges built it: `go build -o main main.go`.
COPY main.go .

RUN go build -o main main.go

# Documents the port the app serves on; the actual mapping happens at `docker run -p`.
EXPOSE 4444

CMD ["./main"]
