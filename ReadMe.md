# UNBENT: Universal Non-intrusive Bus Error Notification & Tracking

This `bus_err_unit` IP handles bus errors. It is developed as part of the PULP project, a joint effort between ETH Zurich and the University of Bologna.

It stores the error source address into a register and translates the error signal to an interrupt for the cores. The bus signals are not modified and only passed into the unit. Below is a rough block-diagram of the implemented functionality.

![Schematic](doc/bus_err_unit.drawio.png)

All requesting addresses are stored in a FIFO, requiring proper configuration for the number of outstanding transactions (the unit will issue a simulation warning). If this bound is exceeded, the address information will no longer update within the unit until it is reset.
If an error occurs on the bus, an interrupt signal will be raised. This signal indicates a valid address and error code within the error FIFO and will remain high while there are errors stored within this FIFO. Reading the error code will pop the FIFO, and if only a single error was present, clear the interrupt. Thus, to gain information about the address, read this before reading the error code.
For burstive protocols (e.g. AXI), the address will always be the address of the original request.

## Protocol Wrappers:
Dedicated wrappers exist for the following protocols.
- [AXI](https://github.com/pulp-platform/axi) (`axi_err_unit_wrap`)
- [OBI](https://github.com/pulp-platform/obi) (`obi_err_unit_wrap`)

## License
All hardware sources and tool scripts are licensed under the Solderpad Hardware License 0.51 (see [LICENSE](LICENSE)).
