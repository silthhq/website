---
title: File storage
description: Local, memory and S3-compatible disks.
---
# File storage

```yaml
# config/storage.yml
default: s3
disks:
  local:  { driver: local, root: storage/app, url: /files }
  s3:
    driver: s3
    bucket: ${S3_BUCKET}
    region: ${S3_REGION:-eu-west-3}
    key: ${S3_KEY}
    secret: ${S3_SECRET}
    endpoint: ${S3_ENDPOINT:-}     # MinIO, Cloudflare R2, Scaleway, Backblaze…
    path_style: false
```

```crystal
disk = Silth.storage            # default disk
disk.put("reports/q4.pdf", bytes, "application/pdf")
disk.get?("reports/q4.pdf")     # Bytes?
disk.read("notes.txt")          # String
disk.exists?("x")  disk.delete("x")  disk.size("x")  disk.list("reports/")
disk.url("avatars/1.png")
disk.temporary_url("reports/q4.pdf", 15.minutes)   # S3 presigned URL
path = Silth.storage(:s3).put_file("avatars", params.file("avatar").not_nil!)
```

The S3 driver implements AWS Signature V4 itself (headers and presigned URLs). Tests: `Silth::Storage.fake`.
