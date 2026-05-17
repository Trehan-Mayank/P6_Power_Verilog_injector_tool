# power-verilog

Power-aware RTL simulation made simple

> **Note:** The `.pv` format is a custom syntax - not an official industry standard (like UPF/CPF).

## Why PowerVerilog?

Testing power-aware designs traditionally requires:
- Complex UPF/CPF power intent files
- Vendor-specific power simulation setup
- Custom power modeling

**PowerVerilog** lets you write power-aware RTL directly in a simple `.pv` format and automatically generates:
- Standard Verilog with corruption logic
- Separate module instances for different power domains
- `ifndef DISABLE_CORRUPTION` guards for simulation control

## Quick Start

### Run the Converter

```bash
# Clone repo
git clone https://github.com/Trehan-Mayank/power-verilog.git

# Convert .pv file to Verilog with corruption
# Output generates in the same directory where you run this command
python3 <path-to>/bin/run.py tests/test_mirror.pv
```

### Input: .pv File

```pv
powermodule top {
  (VDD->power, VSS->ground, VDD_1->power, VSS_1->ground),
  (input a1, input b1, input a2, input b2, output o1, output o2)
};

leaf_inst1 { (.VDD(VDD), .VSS(VSS)) },
             { (.a(a1), .b(b1), .o(o1)) };

leaf_inst2 { (.VDD(VDD_1), .VSS(VSS_1)) },
             { (.a(a2), .b(b2), .o(o2)) };

endpowermodule


powermodule leaf {
  (VDD->power, VSS->ground),
  (input a, input b, output o)
};

assign o = a & b;

endpowermodule
```

### Output: Generated Verilog

```verilog
module top (
    input VDD, input VSS, input VDD_1, input VSS_1,
    input a1, input b1, input a2, input b2,
    output o1, output o2
);
    leaf_m123 #() leaf_inst1 (.VDD(VDD), .VSS(VSS), .a(a1), .b(b1), .o(o1));
    leaf_m456 #() leaf_inst2 (.VDD(VDD_1), .VSS(VSS_1), .a(a2), .b(b2), .o(o2));
endmodule

module leaf_m123 (
    input VDD, input VSS, input a, input b, output o
);
    // Supply: VDD->VDD, VSS->VSS
    `ifndef DISABLE_CORRUPTION
    assign o = (VDD && !(VSS)) ? a & b : 'x;
    `else
    assign o = a & b;
    `endif
endmodule
```

### Output: Testbench Template

```verilog
module tb;
    // Power signals (from generated file)
    logic VDD, VSS, VDD_1, VSS_1;

    // Domain task (from generated file)
    task domain(input int num, input bit [1:0] value);
        if (num == 1) begin VDD = value[1]; VSS = value[0]; end
        if (num == 2) begin VDD_1 = value[1]; VSS_1 = value[0]; end
    endtask

    top u_top (.VDD(VDD), .VSS(VSS), .VDD_1(VDD_1), .VSS_1(VSS_1), ...);

    initial begin
        domain(1, 2'b10);  // Domain1 power on
        domain(2, 2'b10);  // Domain2 power on
        // Test outputs...
    end
endmodule
```

**Value encoding:** `2'b00`=off, `2'b10`=power on, `2'b01`=ground on

## Run Tests

```bash
cd tests
./run.sh
```

## Project Structure

```
power-verilog/
├── src/                  # Python source
│   ├── pv_parser.py         # .pv file parser
│   ├── corruption_injector.py  # Corruption injection
│   └── pv_restructurer.py  # Verilog generation
├── tests/                # Test files
│   ├── *.pv            # Input test files
│   └── *.v             # Generated Verilog
├── project.md           # Detailed documentation
└── README.md            # This file
```

## Features

- Corruption injection
- Feedthrough detection
- DISABLE_CORRUPTION ifdef control

## License

MIT License