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

This command will run the `example.lua` script with 14 threads and 400 connections for 70 seconds.