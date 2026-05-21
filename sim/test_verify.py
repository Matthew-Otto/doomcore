#!/usr/bin/env python3

import os
import shutil
import random
from pathlib import Path
from utils.utils import *
from utils.spike_runner import *
from models.sdram import SDRAM

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.clock import Clock
from cocotb.triggers import Timer, ReadOnly, ReadWrite, ClockCycles, RisingEdge, FallingEdge


async def valid_instr(dut, clk):
    await ReadOnly()
    if dut.cpu.branch_unit.valid.value != 1:
        await RisingEdge(dut.cpu.branch_unit.valid)
        while dut.cpu.stall_EX.value:
            await ClockCycles(clk, 1)
        await ReadOnly()

@cocotb.test()
async def test_verify(dut):
    setup_file_logger(dut._log, "INFO")

    firmware_dir = os.path.join(os.getcwd(), "../../firmware/bin")
    bootloader = os.path.join(firmware_dir, "bootloader.elf")

    if not os.path.isfile(bootloader):
        assert 0, f"Error: bootloader file {bootloader} does not exist"

    ref_sim = SpikeRunner(bootloader)


    dut._log.info(f"Executing Bootloader")

    clk = dut.core_clk
    busclk = dut.bus_clk
    pclk = dut.p_clk
    reset = dut.async_reset

    # init system
    sdram = SDRAM(dut.sdram_i.sdram_controller_i, busclk)
    sys_clk_ps = round((1/80_000_000) * 1e12)
    bus_clk_ps = round((1/160_000_000) * 1e12)
    cocotb.start_soon(Clock(clk, sys_clk_ps, unit="ps").start())
    cocotb.start_soon(Clock(busclk, bus_clk_ps, unit="ps").start())
    cocotb.start_soon(Clock(pclk, 39.682, unit="ns").start())

    cocotb.start_soon(log_sim_speed(dut, clk))
    await FallingEdge(dut.core_clk_rst)

    tracing = True
    iters = 500000
    step = 10000

    for _ in range(0,iters,step):
        if tracing:
            trace = ref_sim.stepn(step)

            if not trace:
                tracing = False

            for instr in trace:
                await valid_instr(dut, clk)

                ref_pc, ref_instr, ref_asm = instr
                sim_pc = dut.cpu.branch_unit.PC.value

                print(f"Ref: {ref_pc} | {ref_instr} | {ref_asm}")
                print(f"Sim: {hex(sim_pc)}")
                # for idx,reg in enumerate(ref_sim.regfile):
                #     print(f"{idx:02} | {hex(reg)}")

                if int(ref_pc,16) != sim_pc:
                    # for idx,reg in enumerate(ref_sim.last_regfile):
                    #     print(f"{idx:02} | {hex(reg)}")
                    await ClockCycles(clk, 2)
                    assert 0, f"Error: PC mismatch at time {get_sim_time(unit='ps')}ps"

                await ClockCycles(clk, 1)
        else:
            for _ in range(step):
                await valid_instr(dut, clk)
                await ClockCycles(clk, 1)

    #await ClockCycles(clk, 100000)
    await ClockCycles(clk, 10)

    #sdram.dump(0x0, 0x100)





def test_runner():
    sim = get_runner("verilator")

    top_module = "top"
    sim_dir = Path(__file__).parent
    firmware_dir = sim_dir.parent / "firmware"
    rtl_dir = sim_dir.parent / "RTL"
    sources = list(rtl_dir.glob("**/*.sv")) # SV source files
    includes = [p.parent for p in list(set(rtl_dir.glob("**/*.svh")))] # SV header files
    includes += [rtl_dir]
    waivers = [str(w) for w in rtl_dir.glob("**/*.vlt")] # Verilator waivers for 3rd party IP

    hex_path = str(firmware_dir / "bin" / "bootloader.hex")

    sim.build(
        sources=sources,
        includes=includes,
        hdl_toplevel=top_module,
        always=False,
        waves=True,
        parameters={
            "BOOT_ROM_FILE": f'"{hex_path}"'
        },
        build_args=[
            "--build", "-j", "12", # Parallelize Compilation
            *waivers,
            "-Wno-SELRANGE",
            "-Wno-WIDTH",
            "--trace-fst",
            "--trace-structs",
            "--threads", "2",
            "--public-flat-rw",
            "--timing",
            "--x-assign", "unique",
            "--x-initial", "unique",
            "--x-initial-edge"
        ],
    )

    sim.test(
        hdl_toplevel=top_module,
        test_module=Path(__file__).stem,
        waves=True,
        gui=True,
        test_args=[
            "+verilator+rand+reset+2",
            "+verilator+seed+1234",
        ],
    )

if __name__ == "__main__":
    test_runner()