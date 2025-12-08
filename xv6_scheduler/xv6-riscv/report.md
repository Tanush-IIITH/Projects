## Implementation Details

### Round-Robin (RR)
- Default preemptive scheduler in xv6 using fixed time slices.
- No changes made to the implementation.

### First-Come, First-Served (FCFS)
- Implemented non-preemptive scheduler that runs processes to completion in arrival order.
- Modified scheduler() to select the oldest process without preemption.

### Completely Fair Scheduler (CFS)
- Implemented virtual runtime (vruntime) based fair scheduling.
- Modified the scheduler() function to select the process with the lowest vruntime.
- Added vruntime field to the proc struct for tracking execution time.
- Processes are preempted when a lower vruntime process becomes available.

### Multilevel Feedback Queue (MLFQ)
- Implemented multiple priority queues with decreasing time slices (1, 2, 4, 8 ticks).
- Processes start in the highest priority queue (0) and are demoted on time slice expiration.
- Promoted back to queue 0 on I/O operations or periodic boost.
- Added priority boost every 100 ticks to prevent starvation.

## Round-Robin Scheduler Performance

**Raw Data (out_rr.txt):**

| PID | Process Type | Run Time | Wait Time |
|-----|--------------|----------|-----------|
| 10  | I/O-Bound    | 24       | 97        |
| 12  | I/O-Bound    | 24       | 98        |
| 13  | I/O-Bound    | 24       | 98        |
| 11  | I/O-Bound    | 25       | 98        |
| 9   | I/O-Bound    | 26       | 97        |
| 4   | CPU-Bound    | 0        | 200       |
| 5   | CPU-Bound    | 0        | 200       |
| 6   | CPU-Bound    | 0        | 200       |
| 7   | CPU-Bound    | 0        | 200       |
| 8   | CPU-Bound    | 0        | 200       |

**Average Metrics:**

- **Average Run Time:** 12.3 ticks  
  *(Calculation: (24+24+24+25+26+0+0+0+0+0)/10)*  
- **Average Wait Time:** 148.8 ticks  
  *(Calculation: (97+98+98+98+97+200+200+200+200+200)/10)*  

---

## FCFS Scheduler Performance

**Raw Data (out_fcfs.txt):**

| PID | Process Type | Run Time | Wait Time |
|-----|--------------|----------|-----------|
| 9   | I/O-Bound    | 25       | 0         |
| 10  | I/O-Bound    | 25       | 25        |
| 11  | I/O-Bound    | 24       | 50        |
| 12  | I/O-Bound    | 24       | 74        |
| 13  | I/O-Bound    | 25       | 98        |
| 4   | CPU-Bound    | 0        | 200       |
| 5   | CPU-Bound    | 0        | 200       |
| 6   | CPU-Bound    | 0        | 200       |
| 7   | CPU-Bound    | 0        | 200       |
| 8   | CPU-Bound    | 0        | 200       |

**Average Metrics:**

- **Average Run Time:** 12.3 ticks  
  *(Calculation: (25+25+24+24+25+0+0+0+0+0)/10)*  
- **Average Wait Time:** 124.7 ticks  
  *(Calculation: (0+25+50+74+98+200+200+200+200+200)/10)*  

---

## CFS Scheduler Performance

**Raw Data (out_cfs.txt):**

| PID | Process Type | Run Time | Wait Time |
|-----|--------------|----------|-----------|
| 9   | I/O-Bound    | 24       | 74        |
| 10  | I/O-Bound    | 25       | 81        |
| 11  | I/O-Bound    | 25       | 88        |
| 12  | I/O-Bound    | 25       | 95        |
| 13  | I/O-Bound    | 25       | 100       |
| 4   | CPU-Bound    | 0        | 220       |
| 5   | CPU-Bound    | 0        | 220       |
| 6   | CPU-Bound    | 0        | 220       |
| 7   | CPU-Bound    | 0        | 220       |
| 8   | CPU-Bound    | 0        | 220       |

**Average Metrics:**

- **Average Run Time:** 12.4 ticks  
  *(Calculation: (24+25+25+25+25+0+0+0+0+0)/10)*  
- **Average Wait Time:** 153.8 ticks  
  *(Calculation: (74+81+88+95+100+220+220+220+220+220)/10)*  

---

## MLFQ Scheduler Performance

**Raw Data (out_mlfq.txt):**

| PID | Process Type | Run Time | Wait Time |
|-----|--------------|----------|-----------|
| 12  | I/O-Bound    | 25       | 62        |
| 13  | I/O-Bound    | 26       | 69        |
| 11  | I/O-Bound    | 25       | 73        |
| 10  | I/O-Bound    | 25       | 99        |
| 9   | I/O-Bound    | 25       | 101       |
| 8   | CPU-Bound    | 0        | 205       |
| 7   | CPU-Bound    | 0        | 205       |
| 6   | CPU-Bound    | 0        | 205       |
| 5   | CPU-Bound    | 0        | 205       |
| 4   | CPU-Bound    | 0        | 205       |

**Average Metrics:**

- **Average Run Time:** 12.6 ticks  
  *(Calculation: (25+26+25+25+25+0+0+0+0+0)/10)*  
- **Average Wait Time:** 142.9 ticks  
  *(Calculation: (62+69+73+99+101+205+205+205+205+205)/10)*  



## Performance Comparison

| Scheduler | Average Run Time (ticks) | Average Wait Time (ticks) |
|-----------|---------------------------|---------------------------|
| RR        | 12.3                      | 148.8                     |
| FCFS      | 12.3                      | 124.7                     |
| CFS       | 12.4                      | 153.8                     |
| MLFQ      | 12.6                      | 142.9                     |

**Analysis:**  
- FCFS shows the lowest average wait time (124.7 ticks) due to its non-preemptive nature and efficient handling of short processes first.  
- RR has moderate wait time (148.8 ticks) with fair preemption.  
- CFS has the highest wait time (153.8 ticks), reflecting its focus on fairness through vruntime, which can lead to longer waits for CPU-bound processes.  
- MLFQ performs well with a wait time of 142.9 ticks, balancing responsiveness for I/O-bound processes through priority queues and periodic boosts.  
- Run times are similar across schedulers, indicating consistent CPU allocation for the I/O-bound processes in the test.

