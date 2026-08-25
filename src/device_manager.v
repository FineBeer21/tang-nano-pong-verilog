module deviceManager (
    input mCLK,
    input en,

    output wire DIN,
    output reg CS,
    output reg DC,
    output reg RST,
    output reg CLK,

    output reg rdy
);

reg clk_phase = 1'b0;

always @(negedge mCLK) begin
    if(en) begin
        clk_phase <= 1'b0;
        CLK <= 1'b0;
    end else begin
        clk_phase <= ~clk_phase;
        CLK <= ~CLK; 
    end
end

reg [21:0] counter = 22'd0;

reg [7:0] tx_data = 8'h00;
assign DIN = tx_data[7];

// states
parameter [2:0] PWR = 3'd0, 
                BOOT = 3'd1,
                SLPOUT = 3'd2,
                COLMOD = 3'd3,
                DISPON = 3'd4,
                FINISH = 3'd5;

reg [2:0] current_state = PWR , next_state;


// clk logic
always @(negedge mCLK) begin
    if(~en && clk_phase) begin
        current_state <= next_state;

        if(current_state != next_state) begin
            counter <= 22'd0;
            //inserting data to tx_data
            case (next_state)
                SLPOUT: tx_data <= 8'h11;
                COLMOD: tx_data <= 8'h3A;
                DISPON: tx_data <= 8'h29; 
                default: tx_data <= 8'd00;
            endcase
        end
        else begin
            counter <= counter + 22'd1;
            if(current_state == COLMOD && counter == 22'd7) tx_data <= 8'h06; // 18-bit pixel
            else tx_data <= {tx_data[6:0], 1'b0};
        end
    end
end

// state logic
always @(*) begin
    case(current_state) 
        PWR: next_state = (counter > 22'd270) ? BOOT : PWR;
        BOOT: next_state = (counter > 22'd3240000) ? SLPOUT : BOOT;
        SLPOUT: next_state = (counter >= 22'd324008) ? COLMOD : SLPOUT;
        COLMOD: next_state = (counter >= 22'd16) ? DISPON : COLMOD; // colmod command and the rgb is 16 bits
        DISPON: next_state = (counter >= 22'd7) ? FINISH : DISPON;
        FINISH: next_state = FINISH;
        default: next_state = PWR;
    endcase
end

// output logic
always @(*) begin
    RST = ~(current_state == PWR);
    // CS
    case (current_state)
        SLPOUT: begin
            if(counter < 22'd8) CS = 0;
            else CS = 1;
        end 
        COLMOD: CS = (counter == 22'd16) ? 1 : 0;
        DISPON: CS = 0;
        default: CS = 1;
    endcase
    DC = (current_state == COLMOD && counter >= 22'd8);
    rdy = (current_state == FINISH);
end
    
endmodule