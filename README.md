# Runway Buildpack Stack

[![Release](https://github.com/hostwithquantum/runway-buildpack-stack/actions/workflows/release.yml/badge.svg)](https://github.com/hostwithquantum/runway-buildpack-stack/actions/workflows/release.yml)
[![Check Meta](https://github.com/hostwithquantum/runway-buildpack-stack/actions/workflows/check-meta.yml/badge.svg)](https://github.com/hostwithquantum/runway-buildpack-stack/actions/workflows/check-meta.yml)

Our buildpack builders for Runway, based on:

- [jammy-full](https://github.com/paketo-buildpacks/builder-jammy-full)
- [noble-builder](https://github.com/paketo-buildpacks/ubuntu-noble-builder)

Builder configuration lives in [`builders/`](./builders/). See the [Paketo docs](https://buildpacks.io/docs/reference/config/builder-config/) for the configuration format.

---

## Meta buildpacks

The [`meta/`](./meta/) directory contains [composite buildpacks](https://buildpacks.io/docs/for-buildpack-authors/concepts/composite-buildpack/) that we maintain for Runway. Each one has a `README.md` describing what it includes.

### Custom buildpacks

> [!TIP]
> These buildpacks work on any platform, not just Runway.

- [deno-buildpack](https://github.com/hostwithquantum/deno-buildpack)
- [static-buildpack](https://github.com/hostwithquantum/static-buildpack)

---

## Releases

Each git tag publishes the following images. Replace `X.Y.Z` with a tag from this repository.

> [!IMPORTANT]
> Availability of older tags is not guaranteed.

### Builders

- `r.planetary-quantum.com/runway-public/runway-buildpack-stack:jammy-full`
- `r.planetary-quantum.com/runway-public/runway-buildpack-stack:jammy-full-X.Y.Z`
- `r.planetary-quantum.com/runway-public/runway-buildpack-stack:noble-full`
- `r.planetary-quantum.com/runway-public/runway-buildpack-stack:noble-full-X.Y.Z`

### Run images

- `r.planetary-quantum.com/runway-public/runway-runimage:jammy-full`
- `r.planetary-quantum.com/runway-public/runway-runimage:jammy-full-X.Y.Z`
- `r.planetary-quantum.com/runway-public/runway-runimage:noble-full`
- `r.planetary-quantum.com/runway-public/runway-runimage:noble-full-X.Y.Z`

---

## Support

- Docker Platform: support@planetary-quantum.com
- Runway: support@runway.horse