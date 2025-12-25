# Changelog

## [0.2.0](https://github.com/dbirks/happy-server/compare/happy-server-chart-v0.1.4...happy-server-chart-v0.2.0) (2025-12-25)


### Features

* **chart:** add init container for database migrations ([ab155ca](https://github.com/dbirks/happy-server/commit/ab155cabb9847b08b30cbd4a5e090d533fc5206b))

## [0.1.4](https://github.com/dbirks/happy-server/compare/happy-server-chart-v0.1.3...happy-server-chart-v0.1.4) (2025-12-23)


### Bug Fixes

* **chart:** only set S3 env vars when MinIO is enabled ([67dd281](https://github.com/dbirks/happy-server/commit/67dd281c83acb58243b4db5a97c8b6d75aff22ba))

## [0.1.3](https://github.com/dbirks/happy-server/compare/happy-server-chart-v0.1.2...happy-server-chart-v0.1.3) (2025-12-23)


### Bug Fixes

* **chart:** disable MinIO by default to reduce deployment complexity ([5a83ef2](https://github.com/dbirks/happy-server/commit/5a83ef2ae832289f94d50f430566668aa0b0fb50))

## [0.1.2](https://github.com/dbirks/happy-server/compare/happy-server-chart-v0.1.1...happy-server-chart-v0.1.2) (2025-12-23)


### Bug Fixes

* **chart:** use Kubernetes native variable substitution for connection strings ([898a60f](https://github.com/dbirks/happy-server/commit/898a60f53b8e4da23dc508d5be5f9a3e9ee6f886))

## [0.1.1](https://github.com/dbirks/happy-server/compare/happy-server-chart-v0.1.0...happy-server-chart-v0.1.1) (2025-12-23)


### Bug Fixes

* **chart:** remove whitespace from template helper outputs ([3226840](https://github.com/dbirks/happy-server/commit/3226840f9dcd4299323ca82b096b677d5889c2dc))

## [0.1.0](https://github.com/dbirks/happy-server/compare/happy-server-chart-v0.0.1...happy-server-chart-v0.1.0) (2025-12-23)


### Features

* add deployment infrastructure with Helm chart and GitHub Actions ([aaf5292](https://github.com/dbirks/happy-server/commit/aaf52921ba291de064329c1a29ad3e38030bd5bb))
* **chart:** add metrics config and document required secrets ([d1aac33](https://github.com/dbirks/happy-server/commit/d1aac3354f2f1557e86d9400ce04a3ad199ff8c5))
* **chart:** add MinIO subchart for S3-compatible object storage ([30c1b69](https://github.com/dbirks/happy-server/commit/30c1b6942c3124895f37aada5e66d5f2aba10edb))
* **chart:** auto-generate HANDY_MASTER_SECRET with persistence ([9b7680e](https://github.com/dbirks/happy-server/commit/9b7680eefe614767608a410ca200013ed9888d8b))
