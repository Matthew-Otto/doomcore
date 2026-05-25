# Base Clock: 27.0 MHz oscillator
# Period = 1000 / 27.0 = 37.037 ns
create_clock -name clk -period 37.037 [get_ports {clk}]

# System Clock
# Period = 1000 / 88.0 = 11.3636 ns
create_clock -name sys_clk -period 11.3636 [get_nets {sys_clk}]

# HDMI Serializer Clock (s_clk): 126.0 MHz 
# Period = 1000 / 126.0 = 7.936 ns
create_clock -name s_clk -period 7.936 [get_nets {s_clk}]

# HDMI Pixel Clock (p_clk): 25.2 MHz
# Period = 1000 / 25.2 = 39.682 ns
create_clock -name p_clk -period 39.682 [get_nets {p_clk}]