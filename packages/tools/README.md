# Tools Package

This folder is **not application code**.  
It exists only to track **developer tools** in `go.mod` so their versions are pinned in the repo.

## Why?

Normally, tools like [Air](https://github.com/air-verse/air) (live reload), [sqlc](https://github.com/sqlc-dev/sqlc) (SQL → Go codegen), or linters are installed globally on a machine.  
That makes builds inconsistent across environments (different versions on each dev machine or CI).

By declaring them in a Go module with a `tools.go` file:

```go
//go:build tools

package tools

import (
    _ "github.com/air-verse/air"
    _ "github.com/sqlc-dev/sqlc/cmd/sqlc"
)
````

…we can track tool dependencies in `go.mod` just like any other package.

This way:

* Everyone uses the same tool versions.
* CI/CD pipelines can reliably install them with `go install`.
* Tools don’t pollute the main application `go.mod` files.

## Usage

1. **Install a tool** (at the version in `go.mod`):

   ```bash
   go install github.com/air-verse/air@latest
   go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
   ```

2. **Update a tool**:

   ```bash
   go get github.com/air-verse/air@v1.63.0
   go get github.com/sqlc-dev/sqlc/cmd/sqlc@v1.27.0
   go mod tidy
   ```

3. **Add a new tool**:
   Add an import to `tools.go` (using `_ "import/path"`) and run `go mod tidy`.

---

## Folder Structure

```
packages/tools/
├── go.mod        # module file to pin tool versions
├── go.sum        # checksums for reproducibility
├── tools.go      # imports all dev tools for tracking
└── README.md     # this file
```

---

## Notes

* This module should **not be imported by app code**.
* It’s only for tool versioning.
* Each app (`apps/api`, `apps/worker`, etc.) stays clean and focused on business logic.