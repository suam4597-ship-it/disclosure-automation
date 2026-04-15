Authoritative local chunks for the remaining large SEC files.

Purpose:
- preserve the exact local workspace content inside PR #20 even when direct overwrite of large existing files is still being staged
- keep the 6-K lock work moving without expanding beyond 6-K

Current focus:
- runtime/sec_adapter.ex
- pipeline.ex
