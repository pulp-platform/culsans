================================================================================
Culsans Unit Test Bench
================================================================================

The Culsans unit test bench verifies the coherency functionality of a system
with two or more CVA6 cores connected with a coherency interconnect. The test
bench uses a modified version of the CVA6 core with everything except the cache
subsystem stripped away.

The test bench applies stimuli directly to the cache CPU ports through a number
of drivers. Several monitors and scoreboards are active to verify the
behaviour.

.. figure:: _static/images/culsans_unit_tb.png
    :alt: Culsans unit test bench

    Culsans unit test bench

.. Unfortunately include:: doesn't work on GitHub, add link instead
.. .. include:: ../../modules/cva6/corev_apu/tb/tb_std_cache_subsystem/README.rst

The verification components are documented in
`cva6/corev_apu/tb/tb_std_cache_subsystem <https://github.com/planvtech/cva6/blob/PROJ-325-add-documentation-for-cache-subsystem-unit-test-bench/corev_apu/tb/tb_std_cache_subsystem/README.rst>`_.


--------------------------------------------------------------------------------
Running the test bench
--------------------------------------------------------------------------------

To run the test bench, do::

    make all TEST=<test case>

To invoke GUI, add ``GUI=1``.

``make`` variables
================================================================================
This section describes some of the ``make`` variables available to change the
behaviour of the test bench. To see all available make targets and variables,
run::

    make help


``ENABLE_ICACHE_RANDOM_GEN``
--------------------------------------------------------------------------------
By default the testbench sends random read requests to the instruction cache
during all tests to stress the system. This behaviour can be turned off by
supplying ``ENABLE_ICACHE_RANDOM_GEN=0`` (e.g. to easy debugging).


``ENABLE_AXI_ID_PER_PORT``
--------------------------------------------------------------------------------
To help the scoreboard determining from which dcache request port a certain AXI
transaction origins, the testbench forces different AXI IDs for the different
ports. Port 0 (PTW) then gets ID ``0xC``, port 1 (load) ``0xD``, and port 2
(store) ``0xE`` (normally they all get ID ``0xC``). Some, but not all, tests
require this to properly predict the expected behaviour. To disable this
forcing, supply ``ENABLE_AXI_ID_PER_PORT=0``.

.. warning::

  The default behaviour of the test bench (``ENABLE_AXI_ID_PER_PORT=1``) changes
  the behaviour of the DUT. However, this change is deemed to be safe.

.. note::

  The CCU scoreboard :code:`ace_ccu_monitor` does not support different AXI IDs per
  dcache port. Therefore, the default behaviour of this testbench is to have the
  CCU scoreboard disabled (``ENABLE_CCU_MON=0``).


--------------------------------------------------------------------------------
Test cases
--------------------------------------------------------------------------------
This section lists all test cases in the unit test bench. During all tests, the
:code:`std_cache_scoreboard` and :code:`dcache_checker` modules are active and
check the correctness of the transactions and cache contents.

In general, the test cases themselves do not perform any additional checks,
unless explicitly specified in the test case description.


read_miss
================================================================================
This test triggers read misses to the same index from a single core.

#. Write to 16 different addresses that map to the same cache index, forcing
   eviction of some of the first written addresses.
#. Read the first 8 addresses again.


write_collision
================================================================================
This test triggers writes from different cores to the same cache index.

For each core, do:

* Repeat multiple times:

  - Write to address *A* mapping to index *I*

  - Wait 0-19 cycles

* Repeat multiple times:

  - Write to address *A+N\*256* mapping to index *I*

  - Wait 0-19 cycles


read_collision
================================================================================
This test triggers the :code:`colliding_read` mechanism in cache controllers,
which detects if a ``ReadShared`` snoop request has changed the state of an
entry to *Shared*  while at the same time that entry is being changed to
*Unique*.

The test repeats the steps below multiple times.

* Get a data into state *SharedClean* in one core by:

  - Read the data in all cores.

  - Force eviction of the data in all but one core.

* Then, in parallel:

  - Write the data in the core that has the data in cache (causing a
    ``ReadUnique`` snoop transaction).

  - Read the data in the other cores (causing a ``ReadShared`` transaction from
    each core).


read_write_collision
================================================================================
This test triggers reads and writes to the same cache index.

For each core, do:

* Repeat multiple times:

  - Write to, or read from, address *A* mapping to index *I*

  - Wait 0-5 cycles

* Repeat multiple times:

  - Write to, or read from, address *A+N\*256* mapping to index *I*

  - Wait 0-19 cycles

  - Write to, or read from, address *A+N\*256+8* mapping to index *I* (upper
    part of cache line)


cacheline_rw_collision
================================================================================
Trigger read from a cacheline while it is being updated.

* Write known data into three addresses (covering two consecutive cache lines)
  in one core.

* In all other cores, do:

  - Read the data from the three addresses - they are now *Shared*

  - In parallel, do:

    - Write to one of the addresses.

    - Read from the other two addresses, verify that data is unchanged.


flush_collision
================================================================================
Flush the cache of one core while another core is accessing its contents.

* Fill the cache in core *A* with writes

* In parallel, do:

  - Flush the cache in core *A*

  - Read from the same addresses from core B in decreasing order and verify the
    result. The decreasing order increases the chances of a collision between an
    entry currently being evicted due to flush and the request for that same
    entry.

.. note::

  In the current implementation of the data cache, a flush will stall any
  incoming snoop requests until the flush is done. Therefore there won't be any
  conflicts. This test was created when the implementation allowed snooping
  requests to be processed while the cache was being flushed and there was a
  possibility for conflicts.


evict_collision
================================================================================
Trigger eviction of a data entry from one core while it is being accessed from
another core.

* Fill cache set ``S`` in core ``A``

* In parallel, do:

  - In core ``A``, cause eviction by reading or writing cache set ``S``.

  - In other cores, access data in set ``S`` by read, write, or AMO.


raw_spin_lock
================================================================================
Emulate the Linux raw_spin_lock / unlock functions.

* In each core, repeat multiple times:

  - repeatedly read one of two lock variables until the response is 0
    (unlocked).

  - try to aquire lock by swapping in 1 using ``AMO_SWAP``.

    - if the lock succeeded (result == 0):

      - wait some time

      - unlock the lock by writing 0.

      - exit loop.

    - if the lock failed (result == 1):

      - go back to reading the lock.

During the test, the :code:`std_cache_scoreboard.check_amo_lock()` task is
active, which flags an error if any of the following occurs:

- A lock request succeeds to an address that is already locked.

- An unlock request succeeds to an address that is not locked, or is locked by
  another core.

- An unlock request fails.


raw_spin_lock_wait
================================================================================
This does the same as the **raw_spin_lock** test, but in each main iteration the
test waits until all cores has successfully aquired the lock once.


amo_read_write
================================================================================
This test sends AMO LR/SC operations to the same address from multiple cores. It
does not predict any results from the operations, the test just verifies that
the generated transactions are as expected.

In each core, repeat a few times:

* Send ``AMO.LR`` to address ``A``

* Wait 0-10 clocks

* Send ``AMO.SC`` to address ``A``


amo_alu
================================================================================
This test send various AMO ALU operations and verifies the result. Both 64-bit
and 32-bit operations are verified. Other cache requests are send simultaneously
to add disturbance and verify data values.

Repeat multiple times:

* Randomize address ``A``.

* Core ``X`` writes known data to address ``A``.

* Core ``X`` possibly (randomize with a 50% chance) writes random data to
  neighboring address (``A+8`` for 64-bit operations, ``A+4`` for 32-bit
  operations).

* Core ``Y`` possibly writes random data to neighboring address.

* Core ``X`` possibly reads data from address ``A`` and verifies the result.

* Core ``X`` sends random AMO ALU operation with a known operand to address
  ``A``.

* Core ``X`` possibly writes random data to neighboring address.

* Core ``Y`` possibly writes random data to neighboring address.

* Core ``Y`` possibly reads data from address ``A`` and verifies the result.

* Core ``X`` reads data from address ``A`` and verifies the result.


amo_cacheline_collision
================================================================================
This test does an ``LR`` / ``SC`` reservation to an address from one core, while
another core writes to a different address within the same cache line. The test
then expects the ``SC`` operation to fail.

This test was developed to trigger bug `PROJ-272
<https://planv.atlassian.net/browse/PROJ-272>`_. However, the bug was misleading
since the reservation set was set to 64 bits at the time it was reported. The
correct/intended usage of the reservation is to be at least the size of a cache
line (128 bits). The reservation has since been changed to 128 bits and the
expected ``SC`` result is to fail.


amo_lr_sc_upper
================================================================================
This test does an ``LR`` / ``SC`` reservation to an address residing in the
upper part of a cache line from one core, while another core writes to the same
address. The conditional store is expected to fail.

This test was developed to trigger bug `PROJ-270
<https://planv.atlassian.net/browse/PROJ-270>`_, where the ``SC`` would succeed
erroneously. The bug has since been fixed and the test passes.


amo_lr_sc_adjacent
================================================================================
This test does an ``LR`` / ``SC`` reservation to an address while another core
writes to the adjacent cache line (address +/- 16). The conditional store is
expected to succed.


amo_lr_sc_single
================================================================================
This test does an ``LR`` to an address, then writes that address with a regular
store from the same core, and then does an ``SC`` to that address. The ``SC`` is
expected to succeed.

This test was developed to trigger `bug 29 in the axi_riscv_atomics repository
<https://github.com/pulp-platform/axi_riscv_atomics/issues/29>`_. However, as is
discussed in the bug report, the current behaviour is that the ``SC`` fails,
which is allowed by the RISC-V spec.

This test is therefore expected to fail and is excluded from the regression test
suite. It is kept for future use if the atomics module is updated to allow this.














random_non-shared
================================================================================
TBD


random_all
================================================================================
TBD


snoop_non-cached_collision
================================================================================
TBD


random_shared_non-shared
================================================================================
TBD


random_shared_amo
================================================================================
TBD


amo_upper_cache_line
================================================================================
TBD


random_cached
================================================================================
TBD


random_non-shared_amo
================================================================================
TBD



amo_read_write_collision
================================================================================
TBD


random_cached_flush
================================================================================
TBD


amo_lr_sc_delay
================================================================================
TBD


amo_lr_sc
================================================================================
TBD


random_cached_shared
================================================================================
TBD


amo_snoop_collision
================================================================================
TBD


amo_read_cached
================================================================================
TBD


amo_snoop_single_collision
================================================================================
TBD


random_cached_non-shared
================================================================================
TBD


read_two_writes_back_to_back
================================================================================
TBD


random_cached_amo
================================================================================
TBD


random_shared
================================================================================
TBD







--------------------------------------------------------------------------------
Limitations
--------------------------------------------------------------------------------

The **dcache_checker** can't be used when a LLC is present in the system. To run
verification with the dcache_checker enabled, the LLC must be bypassed by
supplying ``TB_HAS_LLC=0`` and ``ENABLE_MEM_CHECK=1`` when running a test.
