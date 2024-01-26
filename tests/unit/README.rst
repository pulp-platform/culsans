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
`cva6/corev_apu/tb/tb_std_cache_subsystem <https://github.com/planvtech/cva6/blob/culsans_pulp/corev_apu/tb/tb_std_cache_subsystem/README.rst>`_.


--------------------------------------------------------------------------------
Running the test bench
--------------------------------------------------------------------------------

To see all available make targets and variables, run::

    make help

To run the test bench, do::

    make all TEST=<test case>

To invoke GUI, add ``GUI=1``.

In batch mode, the test will report the first failure (if any) to the terminal.
No failure means success. To see details of the simulation, open the
testlist/<test_case>/sim.log file.


Regression tests and status
================================================================================

To run the regression test suite, do::

    make pass

To see the status of tests, do::

    make status

Note that all tests are not included in the **pass** test suite, so even after a
completed test suite run the status of some tests will be :code:`NOT RUN` (but
no test should have :code:`FAILED`).


Code coverage
================================================================================
To generate code coverage for a test (suite), add ``COVER=1``::

    make pass COVER=1

To get an HTML report after coverage has been generated, do::

    make report_coverage

The report will be generated into the coverage/html folder.


make variables
================================================================================
The section below describes some of the ``make`` variables available to change the
behaviour of the test bench. To see all available variables, do ``make help``.


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

Some of the scoreboard tasks have timeouts that fail if a certain expected event
doesn't happen within a timeout period. For some tests, the timeouts are
increased due to expected long wait times (e.g. waiting for a cache flush). In
each test, a wait time is typically added at the end of the test to catch any
possible pending timeout failures.











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


amo_lr_sc
================================================================================
Directed test to verify the ``LR`` / ``SC`` functionality.

This test has four subparts:

1. LR / SC with 32-bit operations.

* Write known data ``D`` to address ``A``.

* Reserve address ``A`` using ``LR``, expect success.

* Store new data ``D+1`` to address ``A`` using ``SC``, expect success.

* Store new data ``D+2`` to address ``A`` using ``SC``, expect failure.

* Read address ``A`` using regular load, expect success.

2. LR / SC with 64-bit operations

* Same as in 1. but using 64-bit operations.

3. Failing LR / SC

* Core ``X`` writes known data ``D`` to address ``A``.

* Core ``Y`` reserves address ``A`` using ``LR``, expect success.

* Core ``X`` stores new data ``D+1`` to address ``A`` using regular store.

* Core ``Y`` stores new data ``D+3`` to address ``A`` using ``SC``, expect failure.

* Core ``X`` reads address ``A`` using regular load, expect ``D+1``.

4. Successful + failing LR / SC

* Core ``X`` writes known data ``D`` to address ``A``.

* Core ``Y`` reserves address ``A`` using ``LR``, expect success.

* Core ``Y`` stores new data ``D+2`` to address ``A`` using ``SC``, expect success.

* Core ``X`` reads address ``A`` using regular load, expect ``D+2``.

* Core ``Y`` stores new data ``D+3`` to address ``A`` using ``SC``, expect failure.

* Core ``X`` reads address ``A`` using regular load, expect ``D+2``.


amo_lr_sc_adjacent
================================================================================
This test does an ``LR`` / ``SC`` reservation to an address while another core
writes to the adjacent cache line (address +/- 16). The conditional store is
expected to succed.


amo_lr_sc_delay
================================================================================
This test verfies that ``LR`` / ``SC`` reservation works when there are delays
in the AXI bus system.

This test was developed to trigger bug `PROJ-271
<https://planv.atlassian.net/browse/PROJ-271>`_, which has now been fixed.

.. note::

    The test bench adds random delays in the AXI system by default, but this
    test checks that this is actually the case and fails if it is running in a
    system where there is no delay added on the AXI bus.

The test repeats the following steps a few times for a single core:

* Write known data ``D`` to address ``A``.

* Reserve address ``A`` using ``LR``, expect to get ``D``.

* Store new data ``D+1`` to address ``A`` using ``SC``, expect success.

* Store new data ``D+2`` to address ``A`` using ``SC``, expect failure.

* Read address ``A`` using regular load, expect to get ``D+1``.

* Increment ``A`` and ``D``.


amo_lr_sc_single
================================================================================
This test does an ``LR`` to an address, then writes that address with a regular
store from the same core, and then does an ``SC`` to that address. The ``SC`` is
expected to succeed.

This test was developed to trigger `bug 29 in the axi_riscv_atomics repository
<https://github.com/pulp-platform/axi_riscv_atomics/issues/29>`_. However, as is
discussed in the bug report, the current behaviour is that the ``SC`` fails,
which is allowed by the RISC-V spec.

This test is therefore expected to fail and is excluded from the **pass**
regression test suite. It is kept for future use if the atomics module is
updated to allow this.


amo_lr_sc_upper
================================================================================
This test does an ``LR`` / ``SC`` reservation to an address residing in the
upper part of a cache line from one core, while another core writes to the same
address. The conditional store is expected to fail.

This test was developed to trigger bug `PROJ-270
<https://planv.atlassian.net/browse/PROJ-270>`_, where the ``SC`` would succeed
erroneously. The bug has since been fixed and the test passes.


amo_read_cached
================================================================================
This is a directed test targeting bug `PROJ-153
<https://planv.atlassian.net/browse/PROJ-153>`_. The bug caused data residing in
the upper part of the cache line not to be read correctly. Instead, data from
the lower part of the cache line was returned. This bug has now been fixed and
the test passes.

The test writes known data to a complete cache line using regular stores, and
then reads back the data using AMO_LR and verifies the result.


amo_read_write
================================================================================
This test sends AMO LR/SC operations to the same address from multiple cores. It
does not predict any results from the operations, the test just verifies that
the generated transactions are as expected.

In each core, repeat a few times:

* Send ``AMO.LR`` to address ``A``

* Wait 0-10 clocks

* Send ``AMO.SC`` to address ``A``


amo_read_write_collision
================================================================================
This simple test sends AMO operations ``LR`` and ``SC`` from one core while
other cores send regular load and store requests. Transactions are observed and
verified by the scoreboards as usual, no other checks on data is done.


amo_snoop_collision
================================================================================
Send an AMO request, causing flush the cache of one core while another core is accessing its contents.

* Fill the cache in core *A* with writes

* In parallel, do:

  - Send an AMO request from core *A*

  - Read from the same addresses from core B in decreasing order and verify the
    result. The decreasing order increases the chances of a collision between an
    entry currently being evicted due to flush and the request for that same
    entry.

.. note::

  In the current implementation of the data cache, an AMO will not cause a
  flush. Therefore there won't be any conflicts. This test was created when the
  AMO caused a cache flush, which has since been disabled.


amo_snoop_single_collision
================================================================================
This is a directed test targeting bug `PROJ-150
<https://planv.atlassian.net/browse/PROJ-150>`_. The bug caused flush before AMO
to be skipped during certain circumstances. The bug has been fixed, and since
then, flushing before AMO has been disabled.


amo_upper_cache_line
================================================================================
This is a directed test targeting bug `PROJ-151
<https://planv.atlassian.net/browse/PROJ-151>`_. The bug caused write-back of
"next" cache line when doing an AMO operation to the upper part of a dirty cache
line. The bug has been fixed, and the test passes.


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


evict_collision
================================================================================
Trigger eviction of a data entry from one core while it is being accessed from
another core.

* Fill cache set ``S`` in core ``A``

* In parallel, do:

  - In core ``A``, cause eviction by reading or writing cache set ``S``.

  - In other cores, access data in set ``S`` by read, write, or AMO.


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


random_cached, random_shared, random_non-shared
================================================================================
These tests will create random accesses from all cores to addresses within
different address areas:

* random_cached:

  * cacheable, shareable area

  * cacheable, non-shareable area (one core only [1]_)

* random_shared:

  * non-cacheable, shareable area

* random_non-shared:

  * non-cacheable, non-shareable area

Accesses include loads and stores with sizes 1, 2, 4, and 8 bytes. Loads and
stores are requested in parallel, but a single core does not send a load and
store request to the same address in parallel.

The addresses are randomized over the complete address area, but with a 50%
chance to target adresses with an offset of 0..63 from the base address. This is
to increase the chance of address conflicts.


random_cached_flush
================================================================================
This test is similar to **random_cached**, but adds occasional :code:`flush`
requests.


random_cached_amo, random_shared_amo, random_non-shared_amo
================================================================================
These tests are similar to **random_non-shared**, **random_cached**, and
**random_shared** respectively, but includes AMO requests.


random_cached_shared, random_cached_non-shared, random_shared_non-shared, random_all
=====================================================================================
These tests will create random accesses from all cores to addresses within
multiple different address areas:

* random_cached_shared:

  * cacheable, shareable area

  * cacheable, non-shareable area (one core only [1]_)

  * non-cacheable, shareable area

* random_cached_non-shared:

  * cacheable, shareable area

  * cacheable, non-shareable area (one core only [1]_)

  * non-cacheable, non-shareable area

* random_shared_non-shared:

  * non-cacheable, shareable area

  * non-cacheable, non-shareable area

* random_all - all defined areas:

  * cacheable, shareable area

  * cacheable, non-shareable area (one core only [1]_)

  * non-cacheable, shareable area

  * non-cacheable, non-shareable area


Accesses include loads and stores with sizes 1, 2, 4, and 8 bytes, and AMO
requests of size 4 or 8 bytes. Loads, stores, and AMO are requested in parallel,
but a single core does not send a load and store request to the same address in
parallel.

The addresses are randomized over the complete address area, but with a 50%
chance to target adresses with an offset of 0..63 from the base address. This is
to increase the chance of address conflicts.


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


read_miss
================================================================================
This test triggers read misses to the same index from a single core.

#. Write to 16 different addresses that map to the same cache index, forcing
   eviction of some of the first written addresses.
#. Read the first 8 addresses again.


read_two_writes_back_to_back
================================================================================
This is a directed test targeting bug `PROJ-147
<https://planv.atlassian.net/browse/PROJ-147>`_. If a single cache controller
gets a load request immediately followed by two store requests, all to the same
address, then the data from the second store is discarded.

This is however not a valid scenario since in the current CVA6 core each cache
controller only receives loads *or* stores (not both). The test is excluded from
the **pass** regression list.


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


snoop_non-cached_collision
================================================================================
This is a directed test targeting bug `PROJ-149
<https://planv.atlassian.net/browse/PROJ-149>`_. The bug caused a deadlock when
one core was accessing the AXI bypass bus while another core issued e.g. a
``CleanInvalid`` coherence transaction. The bug has been fixed and the test now
passes.


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


.. [1] With the current configuration options, it is not possible to assign
    different private cached areas to different cores. Having multiple cores
    using the same cached areas for private (non-shared) data doesn't make sense
    and would cause incoherent behaviour.

--------------------------------------------------------------------------------
Limitations
--------------------------------------------------------------------------------

The **dcache_checker** can't be used when a LLC is present in the system. To run
verification with the dcache_checker enabled, the LLC must be bypassed by
supplying ``TB_HAS_LLC=0`` and ``ENABLE_MEM_CHECK=1`` when running a test.
