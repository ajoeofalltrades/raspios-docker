# Performance Requirements
- All CLI tools must execute in ≤ 1 second under typical CI load.
- Network calls must include timeouts: 3s connect, 5s read.
- Retry logic may not exceed a 15-second ceiling per run.
- Long-running jobs must stream output to avoid CI timeouts.