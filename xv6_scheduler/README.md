# xv6 Kernel Enhancements: System Call, FCFS Scheduler, and CFS

This project extends the MIT xv6 operating system with kernel-level features for system call development, CPU scheduling policies, fairness, and performance analysis. The modifications transform xv6 from its default round-robin scheduler into a more realistic, Linux-inspired scheduling environment.

## Overview

Modern operating systems rely heavily on efficient scheduling and accurate system-wide accounting. This project implements:

- A new system call for global read-byte tracking
- A First-Come First-Serve (FCFS) scheduling algorithm
- A simplified Completely Fair Scheduler (CFS) inspired by Linux
- An optional preemptive Multi-Level Feedback Queue (MLFQ) scheduler

These additions required modifying xv6's process management, timer interrupt flow, system call table, and scheduler logic.

## 🔧 System Call: Global Read Counter (`getreadcount()`)

To enhance observability inside the kernel, a new system call `getreadcount()` was added. It returns the **total number of bytes read** by all processes since system boot.

## Key Features

System call that returns the total number of bytes read globally across all processes. Demonstrates:

- Tracks bytes returned by every `read()` syscall
- Implemented in the kernel and exposed to user space
- Automatically wraps to 0 on overflow
- Provides OS-level insight into system-wide I/O usage

A user program (`readcount`) demonstrates this behavior by reading data from a file and observing the counter increase.

## First-Come First-Serve (FCFS) Scheduling

FCFS scheduling reflects one of the simplest real-world CPU scheduling policies. To support FCFS:

- Each process stores its creation timestamp
- The scheduler always selects the earliest-created runnable process
- A process runs non-preemptively until it blocks or terminates

This required modifying the process control block (`struct proc`) and the main scheduler loop (`scheduler()`).

Build using:

```bash
make clean
make qemu SCHEDULER=FCFS
```

## Completely Fair Scheduler (CFS)

Inspired by the Linux CFS, this scheduler aims to give each process an equal share of CPU time, weighted by priority.

### Nice Values & Weights

Each process has a nice value (−20 to +19). Weight is computed using:

```
weight = 1024 / (1.25 ^ nice)
```

More negative values indicate higher priority.

### Virtual Runtime

Each process maintains a `vruntime` representing normalized CPU usage:

```
vruntime += (ticks_run * 1024 / weight)
```

### Scheduling Logic

- Runnable processes are ordered by `vruntime`
- The process with the smallest `vruntime` is always chosen
- Processes receive time slices based on:

```
time_slice = max(3, target_latency / runnable_processes)
```

with `target_latency = 48 ticks`.

### Built-in Logging

Before every scheduling decision, the kernel prints:

```
PID | vruntime
Chosen process
```

This helps visualize fairness across processes.

Build using:

```bash
make clean
make qemu SCHEDULER=CFS
```

## Performance Comparison

Using xv6's built-in `schedulertest`, the schedulers were compared (single CPU):

| Scheduler | Characteristics | Behavior Summary |
|-----------|-----------------|------------------|
| Round Robin | Time-slice based | Simple but may cause unfairness |
| FCFS | Non-preemptive | Can cause long waiting (convoy effect) |
| CFS | Fair-share scheduling | Provides balanced waiting times |

CFS demonstrates more consistent and fair CPU distribution across processes.

## Kernel Changes Overview

Major modifications were made in:

```
kernel/
  proc.c - scheduler logic, vruntime updates
  proc.h - added fields: creation_time, nice, weight, vruntime
  sysproc.c - implementation of getreadcount()
  syscall.c - syscall routing
  syscall.h - syscall numbers
  trap.c - tick handling for preemption in CFS

user/
  readcount.c - test program for system call

Makefile - scheduler selection via SCHEDULER= flag
```

## What This Project Demonstrates

- Kernel-level programming in xv6
- Designing and implementing CPU scheduling algorithms
- System call creation and integration
- Fairness and runtime accounting in schedulers
- Cooperative vs preemptive scheduling
- Debugging inside an operating system

## Possible Extensions

- Implement Linux-style red-black tree runqueue
- Add `sched_yield` behavior for CFS
- Add load balancing for multi-core scheduling
- Visualize vruntime graphs across ticks

## Running xv6 with Different Schedulers

### Default Round Robin

```bash
make qemu
```

### FCFS

```bash
make clean
make qemu SCHEDULER=FCFS
```

### CFS

```bash
make clean
make qemu SCHEDULER=CFS
```
