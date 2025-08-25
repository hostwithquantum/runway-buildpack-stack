FROM r.planetary-quantum.com/buildpacks/dotnet-core:3.1.6 AS pack0
FROM r.planetary-quantum.com/buildpacks/go:4.12.64 AS pack1
FROM r.planetary-quantum.com/buildpacks/java-native-image:11.15.3 AS pack2
FROM r.planetary-quantum.com/buildpacks/java:18.12.3 AS pack3
FROM r.planetary-quantum.com/buildpacks/nodejs:9.3.2 AS pack4
FROM docker.io/paketobuildpacks/php:2.19.9 AS pack5
FROM docker.io/paketobuildpacks/procfile:5.11.3 AS pack6
FROM docker.io/paketobuildpacks/python:2.29.6 AS pack7
FROM r.planetary-quantum.com/buildpacks/ruby:0.47.9 AS pack8
FROM docker.io/paketobuildpacks/web-servers:2.6.0 AS pack9
FROM r.planetary-quantum.com/buildpacks/deno:0.5.0 AS pack10
FROM r.planetary-quantum.com/buildpacks/runway:0.1.2 AS pack11
FROM paketobuildpacks/builder-jammy-buildpackless-full:latest as lifecycle
FROM docker.io/paketobuildpacks/build-jammy-full:0.1.96 AS base
COPY --from=lifecycle /cnb /
COPY --from=lifecycle /lifecycle /cnb/lifecycle
COPY --from=pack0 /cnb /cnb
COPY --from=pack1 /cnb /cnb
COPY --from=pack2 /cnb /cnb
COPY --from=pack3 /cnb /cnb
COPY --from=pack4 /cnb /cnb
COPY --from=pack5 /cnb /cnb
COPY --from=pack6 /cnb /cnb
COPY --from=pack7 /cnb /cnb
COPY --from=pack8 /cnb /cnb
COPY --from=pack9 /cnb /cnb
COPY --from=pack10 /cnb /cnb
COPY --from=pack11 /cnb /cnb
LABEL "io.buildpacks.builder.metadata"="{\"stack\": {\"runImage\": {\"image\": \"r.planetary-quantum.com/runway-public/runway-runimage:jammy-full\",\"mirrors\": null}},\"lifecycle\": {\"version\": \"0.20.13\",\"api\": {\"buildpack\": \"0.7\",\"platform\": \"0.7\"},\"apis\":{\"buildpack\": {\"deprecated\": [],\"supported\": [\"0.7\",\"0.8\",\"0.9\",\"0.10\",\"0.11\"]},\"platform\":{\"deprecated\": [],\"supported\": [\"0.7\",\"0.8\",\"0.9\",\"0.10\",\"0.11\",\"0.12\",\"0.13\",\"0.14\"]}}}}"
ENV CNB_USER_ID=1001
ENV CNB_GROUP_ID=1000
ENV CNB_STACK_ID=io.buildpacks.stacks.jammy
COPY order.toml /cnb/order.toml
COPY stack.toml /cnb/stack.toml
COPY run.toml /cnb/run.toml
USER 1001:1000
