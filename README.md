# Benchmarks

## Intro

This is a collection of lua scripts for benchmarking (T) services. The banchmark scripts are written for [WRK](https://github.com/wg/wrk) to simulate the load on the servers.

## Usage

1. Install wrk (https://github.com/wg/wrk)

```bash
brew install wrk
```

2. Run the benchmark

```bash
wrk -s ./example.lua -t14 -c400 -d70s http://127.0.0.1:2998
```

This command will run the `proxy-dps-health-random.lua` script with 14 threads and 400 connections for 70 seconds.

## Scripts

- `proxy-dps-health-random.lua`: This script sends random health requests to the DPS microservice. It takes in randomSize parameter (e.g `randomSize = "0.5:0.001,0.35:0.01,0.1:0.1,0.05:1.0"`)  which is a string of comma separated pairs of size and probability. The size is the size of the request in MB and the probability is the probability of the request size.
- `proxy-docstore-get.lua`: This script fetches a dummy document from the docstore microservice.
- `wb-proxy-dedbusiness-authenticateuser`: This script sends a request to the dedbusiness microservice to authenticate a user through the WB proxy.
