module top (
    input wire clk,

    input BUT_D1, BUT_U1,
          BUT_D2, BUT_U2,
    
    output wire LCD_DIN,
    output wire LCD_CLK,
    output wire LCD_CS,
    output wire LCD_DC,
    output wire LCD_RST
);

wire rdy;
wire dev_din, dev_clk, dev_cs, dev_dc, dev_rst;
wire drv_din, drv_clk, drv_cs, drv_dc;

// draw logic
wire [7:0] x_cord, y_cord;
wire draw, calc_next_frame;

// buttons
wire d1, u1, d2, u2;

buttonDebouncer u_d1 (
    .d (BUT_D1),
    .CLK (clk),
    .RES (~rdy),
    .sd (d1)
);

buttonDebouncer u_u1 (
    .d (BUT_U1),
    .CLK (clk),
    .RES (~rdy),
    .sd (u1)
);

buttonDebouncer u_d2 (
    .d (BUT_D2),
    .CLK (clk),
    .RES (~rdy),
    .sd (d2)
);

buttonDebouncer u_u2 (
    .d (BUT_U2),
    .CLK (clk),
    .RES (~rdy),
    .sd (u2)
);

deviceManager u_device_manager(
    .mCLK (clk),
    .en (1'b0),
    .DIN (dev_din),
    .CS (dev_cs),
    .DC (dev_dc),
    .RST (dev_rst),
    .CLK (dev_clk),
    .rdy (rdy)
);

st7735Driver u_driver (
    .reset (~rdy),
    .mCLK (clk),
    .DIN (drv_din),
    .CLK (drv_clk),
    .CS (drv_cs),
    .DC (drv_dc),
    .x_cord (x_cord),
    .y_cord (y_cord),
    .draw (draw),
    .rdy (calc_next_frame)
);

pongEngine u_pong_engine (
    .RES (~rdy),
    .CLK (clk),
    .x_cord (x_cord),
    .y_cord (y_cord),
    .draw (draw),
    .cont (calc_next_frame),

    .d1 (d1),
    .u1 (u1),
    .d2 (d2),
    .u2 (u2)
);

assign LCD_DIN = rdy ? drv_din : dev_din;
assign LCD_CLK = rdy ? drv_clk : dev_clk;
assign LCD_CS = rdy ? drv_cs : dev_cs;
assign LCD_DC = rdy ? drv_dc : dev_dc;
assign LCD_RST = dev_rst;
    
endmodule