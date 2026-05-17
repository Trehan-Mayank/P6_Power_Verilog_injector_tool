# Power Verilog (.pv) Project

A tool for converting power-aware `.pv` files to standard Verilog with corruption injection for power-aware simulation.

## .pv File Syntax

### 1. Powermodule Declaration

```pv
powermodule <module_name> {
  (<power_supplies>),
  (<port_definitions>)
};
// Supply port description: <description>
```

**Example:**
```pv
powermodule top {
  (VDD->power, VSS->ground, VDD_1->power, VSS_1->ground),
  (input a, input b, output o)
};
// Supply port description: VDD->power, VSS->ground, VDD_1->power, VSS_1->ground
```

### 2. Power Supply Definition

- Format: `<port_name>-><type>`
- Types: `power`, `ground`
- Multiple supplies separated by commas

### 3. Port Definitions

- `input <name>` - Input port
- `output <name>` - Output port

### 4. Assignments (Combinational Logic)

```pv
assign <lhs> = <expression>;
```

**Example:**
```pv
assign o = a & b;
assign o = a | b;
assign o = a ^ b;
```

### 5. Instance Declaration (with power connections)

```pv
<module_type> <instance_name> { (.power_port(power_net), ...) },
                               { (.signal_port(signal), ...) };
```

**Example:**
```pv
leaf_inst1 { (.VDD(VDD_1), .VSS(VSS_1)) },
             { (.a(a1), .b(b1), .o(o1)) };
```

### 6. Instance Declaration (without power connections - simple Verilog style)

```pv
<module_type> <instance_name> (.port1(signal1), .port2(signal2));
```

**Example:**
```pv
child2 (.a(a2), .b(b2), .o(o2));
```

### 7. Standard Verilog Module

```pv
module <module_name> (input a, input b, output o);
// Standard Verilog module
assign o = a & b;
endmodule
```

### 8. Special Cell Types

#### Isolation Cell
```pv
iso_cell <instance_name> { (.VDD(power_net), .VSS(ground_net)) },
                          { (.in(signal), .iso_en(enable), .out(output), .clamp(value)) };
```

#### Power Switch
```pv
power_switch <instance_name> { (.VDD1(pwr1), .VSS1(gnd1), .VDD2(pwr2), .VSS2(gnd2)) },
                              { (.in(signal), .iso_en(enable), .out(output)) };
```

### 9. Comments

Single-line comments start with `//`

## Progress

### Completed Features

1. **Parsing**
   - Powermodule declarations with power supplies and port definitions
   - Standard Verilog module support
   - Instance declarations (both with and without power connections)
   - Combinational assignments (`assign` statements)
   - Feedthrough detection (simple signal connections like `assign o = a;`)
   - Special cells: isolation cells, power switches

2. **Corruption Engine**
   - Power-aware corruption injection for powermodules
   - Module mirroring for different power domains
     - Creates unique mirrored versions when same module used with different power connections
     - Mirrored modules get corruption logic based on their specific power connections
   - Feedthrough preservation (simple assignments not corrupted)
   - DISABLE_CORRUPTION ifdef guards for simulation control

3. **Code Generation**
   - Generate standard Verilog from .pv files
   - Only output used modules (filter unused modules)
   - Smart supply port filtering (only include ports used in logic or instances)
   - Supply port description comments
   - Corruption ifdef wrapper with else branch for original logic

4. **Bug Fixes**
   - Fixed statement extraction for powermodules ending with `}` (no semicolon)
   - Fixed double corruption on mirrored modules
   - Fixed unused module filtering
   - Fixed extra/unnecessary supply ports in generated modules

### Key Files

- `src/pv_parser.py` - Parser for .pv files
- `src/corruption_injector.py` - Corruption injection logic
- `src/pv_restructurer.py` - Verilog generation
- `src/pv_to_verilog.py` - Main entry point
- `bin/run.py` - CLI runner

### Usage

```bash
# Run the converter
cd /media/sf_shared/vscode_shared/project_power_verilog
PYTHONPATH=src python3 bin/run.py tests/test_mirror.pv

# Or import in Python
from pv_parser import PvParser
from corruption_engine import CorruptionEngine
from pv_restructurer import PvRestructurer

parser = PvParser()
modules = parser.parse_file('tests/test_mirror.pv')
engine = CorruptionEngine(modules)
engine.inject_corruption()
restructurer = PvRestructurer(modules)
verilog = restructurer.generate_verilog()

# Save to file
with open('tests/design.v', 'w') as f:
    f.write(verilog)
```

### Generated Output Features

- `ifndef DISABLE_CORRUPTION` guards control corruption enable/disable
- Corruption: `assign o = (VDD && !(VSS)) ? original : 'x;`
- Else branch: `assign o = original;`

### Test Examples

- `tests/test_mirror.pv` - Module mirroring with different power domains
- `tests/test_design.pv` - Hierarchical design with multiple children
- `tests/test_with_iso.pv` - Isolation cells and power switches
- `tests/test_module_dup.pv` - Same module with different power connections
- `tests/test_feedthrough.pv` - Feedthrough detection
- `tests/simple_and.pv` - Simple AND gate example

### Testbench Generation

Generated `.v` files include comments showing what to copy into your testbench:

```verilog
// Power signals (define in tb)
// logic VDD;
// logic VSS;
// logic VDD_1;
// logic VSS_1;

// Domain control task (define in tb)
// Usage: domain(1, 2'b10); // value: 00=off, 10=pwr, 01=gnd, 11=both
// task domain(input int num, input bit [1:0] value);
//     if (num == 1) begin VDD = value[1]; VSS = value[0]; end
//     if (num == 2) begin VDD_1 = value[1]; VSS_1 = value[0]; end
// endtask
```

### Testbench Usage

```verilog
module tb;
    // Copy power signals from generated file
    logic VDD, VSS, VDD_1, VSS_1;

    // Copy domain task from generated file
    task domain(input int num, input bit [1:0] value);
        if (num == 1) begin VDD = value[1]; VSS = value[0]; end
        if (num == 2) begin VDD_1 = value[1]; VSS_1 = value[0]; end
    endtask

    // Your design
    top u_top (.VDD(VDD), .VSS(VSS), ...);

    initial begin
        // Domain 1 power on
        domain(1, 2'b10);
        
        // Domain 2 off
        domain(2, 2'b00);
        
        // Domain 1 ground on (corrupts output)
        domain(1, 2'b01);
    end
endmodule
```

**Value encoding:**
- `2'b00` = OFF (power off, ground off)
- `2'b10` = Power ON (VDD=1, VSS=0)
- `2'b01` = Ground ON (VDD=0, VSS=1)
- `2'b11` = Both ON (VDD=1, VSS=1 - still corrupts!)

### Running Tests

```bash
cd tests
./run.sh
```

### Known Limitations

- Single-line assignments only
- No procedural logic (always blocks, initial blocks)
- No parameterized modules
- No generate statements
- Power state modeling not implemented (retention, power gating simulation)