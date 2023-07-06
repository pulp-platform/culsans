# Culsans - tightly-coupled cache coherence unit using the ACE protocol

## Introduction

Aim of this project is the development of a tightly-coupled cache coherence unit for a multicore processor based on [CVA6](https://github.com/openhwgroup/cva6).
Like the ancient god (*), its responsibilities are to maintain order (and data consistency) among the memory accesses performed by the 2~4 CPUs which are part of the system.

(*) [Culsans](https://en.wikipedia.org/wiki/Culsans) – the Etruscan version of [Janus](https://en.wikipedia.org/wiki/Janus), the two-faced and also four-faced god, god of the first and last of the year, of the beginning and the end, of the cardinal points and thus of order in general.

## Getting started

```
git clone https://github.com/planvtech/culsans.git --recursive
```

### Synthesis on FPGA (Genesys2)

```
make fpga
```

### SD image generation

Make sure all dependencies specified in [`cva6-sdk`](cva6-sdk/README.md) are fulfilled.

```
make sdk
```

Then follow the instruction in [`cva6-sdk`](cva6-sdk/README.md) to copy the generated image to the SD.

### RTL tests

Sanity check

```
make sanity-tests
```

Regression tests

```
make test
```
