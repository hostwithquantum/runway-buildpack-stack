# Runway Buildpack

This defines our Buildpack Builder - currently very much based on
https://github.com/paketo-buildpacks/builder-jammy-full

builder.toml docs: https://buildpacks.io/docs/reference/config/builder-config/

The `meta/` directory holds ["meta"/composite buildpacks](https://buildpacks.io/docs/for-buildpack-authors/concepts/composite-buildpack/),
when we needed to patch them. But most are directly from upstream.

On **git tags**, this pushes:

* `r.planetary-quantum.com/runway-public/runway-buildpack-stack:jammy-full`
* `r.planetary-quantum.com/runway-public/runway-buildpack-stack:jammy-full-vX.X.X`
* and the run-image `r.planetary-quantum.com/runway-public/runway-runimage` with the same tags
