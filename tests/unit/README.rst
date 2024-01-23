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

To invoke GUI, add ``GUI=1``. For more options, run ``make help``.


--------------------------------------------------------------------------------
Test cases
--------------------------------------------------------------------------------
This section lists all test cases in the unit test bench. During all tests, the
**std_cache_scoreboard** and **dcache_checker** modules are active and checking
the correctness of the transactions and cache contents.

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
entry to *Shared* (``S*``) while at the same time that entry is being changed to
*Unique* (``U*``).

The test repeats the steps below multiple times.

* Get a data into state ``SC`` in one core by:

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

  - Write to, or read from, address *A+N\*256+8* mapping to index *I* (upper part of cache line)


cacheline_rw_collision
================================================================================
Trigger read from a cacheline while it is being updated.

* Write known data into three addresses (covering two consecutive cache lines) in one core.

* In all other cores, do:

  - Read the data from the three addresses - they are now *Shared*

  - In parallel, do:

    - Write to one address.

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

Note: in the current implementation of the dcache, a flush will halt any
incoming snoop requests until the flush is done. Therefore there won't be any
conflicts. This test was created when the implementation allowed snooping
requests while the cache was being flushed and there was a possibility for
conflicts.


evict_collision
================================================================================
TBD





random_non-shared
================================================================================
TBD


random_all
================================================================================
TBD


amo_read_write
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


raw_spin_lock_wait
================================================================================
TBD



amo_alu
================================================================================
TBD


raw_spin_lock
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


amo_lr_sc_adjacent
================================================================================
TBD


amo_lr_sc_single
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


amo_lr_sc_upper
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


amo_cacheline_collision
================================================================================
TBD





--------------------------------------------------------------------------------
Limitations
--------------------------------------------------------------------------------

The **dcache_checker** can't be used when a LLC is present in the system. To run
verification with the dcache_checker enabled, the LLC must be bypassed by
supplying ``TB_HAS_LLC=0`` and ``ENABLE_MEM_CHECK=1`` when running a test.
