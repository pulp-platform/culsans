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

TBD

--------------------------------------------------------------------------------
Limitations
--------------------------------------------------------------------------------

The **dcache_checker** can't be used when a LLC is present in the system. To run
verification with the dcache_checker enabled, the LLC must be bypassed by
supplying ``TB_HAS_LLC=0`` and ``ENABLE_MEM_CHECK=1`` when running a test.
