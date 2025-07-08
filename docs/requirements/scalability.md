# Scalability Requirements
- All tools must support concurrent CI executions without race conditions.
- Avoid shared temporary files or system-level side effects.
- Mirror URLs must be configurable via env flags or args.