import os
import pexpect
import re
import sys

# this is a dirty hack, but spike kinda sucks so it can't be avoided
class SpikeRunner:
    def __init__(self, elf_file):
        self.elf_file = elf_file

        self.regfile = []
        self.entry_pc = "0x20000000"

        cmd = [
            "spike",
            "-d",
            "--isa=RV32IM",
            "-m0x20000000:0x400,0x30000000:0x10000,0x80000000:0x800000",
            f"--pc={self.entry_pc}",
            elf_file
        ]

        print(f"Launching Spike simulator with {elf_file} | {" ".join(cmd)}")
        env = os.environ.copy()
        env['TERM'] = 'dumb' # strips out terminal characters

        self.process = pexpect.spawn(cmd[0], cmd[1:], env=env, encoding="utf-8")
        self.process.setecho(False)
            
        self.instr_pattern = re.compile(r"(0x[0-9a-fA-F]+)\s+\((0x[0-9a-fA-F]+)\)\s+(.*)")
        self.prompt_regex = r"(?:\r?\n|^): "
            
        match_index = self.process.expect([
            self.prompt_regex,
            r"terminate called",
        ])
        
        # If matched on anything except index 0 (the prompt), it's probably a crash
        if match_index != 0:
            print("\nERROR:")
            # Grab the matched text, what came before it, and anything left in the buffer
            matched_text = str(self.process.after) if self.process.after else ""
            before_text = str(self.process.before) if self.process.before else ""
            remaining_text = self.process.read() if not self.process.closed else ""
            
            print((before_text + matched_text + remaining_text).strip())
            sys.exit(1)

        self.run_until(self.entry_pc)
        

    def exec_cmd(self, cmd):
        print(f"Executing: '{cmd}'")
        self.process.sendline(cmd)
        self.process.expect(self.prompt_regex)
        output = self.process.before
        if output.startswith(cmd):
            output = output[len(cmd):]
        return output.strip()
    
    def parse_instruction(self, line): # returns (pc, encoded instr, asm instr)
        pattern = r"(0x[0-9a-fA-F]+)\s+\((0x[0-9a-fA-F]+)\)\s+(.*)"
        match = self.instr_pattern.search(line)
        if match:
            return match.group(1), match.group(2), match.group(3).strip()
        return None


    def run_until(self, untilpc):
        self.exec_cmd(f"until pc 0 {untilpc}")

    def step(self):    
        output = self.exec_cmd("r 1")
        print(output)
        self.dump_regfile()
        return self.parse_instruction(output)
    
    def stepn(self, n=1):
        output = self.exec_cmd(f"r {n}")
        lines = output.splitlines()
        parsed_instructions = []
        for line in lines:
            if instr:= self.parse_instruction(line):
                parsed_instructions.append(instr)
                
        return parsed_instructions


    def dump_regfile(self):
        reg_dump = self.exec_cmd("reg 0")
        self.last_regfile = self.regfile
        self.regfile = [int(v,16) for v in reg_dump.split() if ":" not in v]

    def regs(self):
        return self.regfile
