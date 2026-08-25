module st7735Driver (
    input reset,
    input mCLK,
    input draw,

    output wire [7:0] x_cord, y_cord,
    output wire DIN,
    output reg CLK,
    output reg CS,
    output reg DC,
    output wire rdy
);


//clk divider - 2:1 ratio making it about 41 FPS
reg clk_phase = 1'b0;

always @(negedge mCLK or posedge reset) begin
    if(reset) begin
        clk_phase <= 1'b0;
        CLK <= 1'b0;
    end else begin
        clk_phase <= ~clk_phase;
        CLK <= ~CLK; 
    end
end


assign DIN = tx_data[7];

// counters and data
reg [7:0] tx_data = 8'h2A;
reg [2:0] bit_counter = 3'd0;
reg [1:0] byte_counter = 2'd0;
reg [15:0] pixel_counter = 16'd0; // Actually there half the pixels but each pixel is 2 bytes so...


//FSM
parameter [2:0] CCA = 3'd0,
                DCA = 3'd1,
                CRA = 3'd2,
                DRA = 3'd3,
                RAMWR = 3'd4,
                DATA = 3'd5,
                FINISH = 3'd6;


reg [2:0] current_state = CCA, next_state;

// cord system
reg [7:0] next_x_cord = 8'd1, next_y_cord = 8'd0;
assign x_cord = next_x_cord;
assign y_cord = next_y_cord;

wire [7:0] wha_color = draw ? 8'hFF : 8'h00;

assign rdy = (current_state == FINISH && bit_counter == 3'd7);

// clk cycle logic
always @(negedge mCLK or posedge reset) begin
    if(reset) begin
        current_state <= CCA;
        tx_data <= 8'h2A;
        bit_counter <= 3'd0;
        byte_counter <= 2'd0;
        pixel_counter <= 16'd0;
    end else if(clk_phase) begin
        current_state <= next_state;
        // counter update
        bit_counter <= bit_counter + 3'd1;
        if((current_state == DCA || current_state == DRA) && bit_counter == 3'd7) byte_counter <= byte_counter + 2'd1;
        if(bit_counter == 3'd7 && current_state == DATA) pixel_counter <= pixel_counter + 16'd1;
        if(current_state == FINISH) pixel_counter <= 16'd0;
        // update tx_data
        if(bit_counter == 3'd7) begin
            // Update tx_data based on current state, all of the commands adresses
            case (current_state)
                CCA: tx_data <= 8'h00;
                DCA: begin
                    if(byte_counter == 2'd0) tx_data <= 8'h02;
                    else if(byte_counter == 2'd2) tx_data <= 8'h81;
                    else if(byte_counter == 2'd3) tx_data <= 8'h2B;
                    else tx_data <= 8'h00;
                end 
                CRA: tx_data <= 8'h00;
                DRA: begin
                    if(byte_counter == 2'd2) tx_data <= 8'hA1;
                    else if(byte_counter == 2'd3) begin
                        tx_data <= 8'h2C;
                        next_x_cord <= 8'd1;
                        next_y_cord <= 8'd0;
                    end
                    else tx_data <= 8'h00;
                end
                RAMWR: begin
                     tx_data <= 8'h00;  
                     byte_counter <= 2'd0;
                end
                DATA: begin
                    //checking what is the next cord set
                    if(byte_counter == 2'd2) begin
                        byte_counter <= 2'd0;
                        if(next_x_cord >= 8'd127) begin
                            next_x_cord <= 8'd0;
                            next_y_cord <= next_y_cord + 8'd1;
                        end else next_x_cord <= next_x_cord + 8'd1;
                    end else byte_counter <= byte_counter + 2'd1;
                    // coloring if needed
                    tx_data <= wha_color;
                end
                FINISH: tx_data <= 8'h2A;
                default: tx_data <= 8'h2A;
            endcase
        end
        else tx_data <= {tx_data[6:0], 1'b0};
    end
    
end

// FSM logic
always @(*) begin
    case(current_state)
        CCA: next_state = (bit_counter == 3'd7) ? DCA : CCA;
        DCA: next_state = (bit_counter == 3'd7 && byte_counter == 2'd3) ? CRA : DCA;
        CRA: next_state = (bit_counter == 3'd7) ? DRA : CRA;
        DRA: next_state = (bit_counter == 3'd7 && byte_counter == 2'd3) ? RAMWR : DRA;
        RAMWR: next_state = (bit_counter == 3'd7) ? DATA : RAMWR;
        DATA: next_state = (bit_counter == 3'd7 && pixel_counter == 16'd62207) ? FINISH : DATA;
        FINISH: next_state = (bit_counter == 3'd7) ? CCA : FINISH;
        default: next_state = CCA;
    endcase
end

// output logic
always @(*) begin
    CS = (current_state == FINISH || reset);

    // DC
    case(current_state)
        DCA: DC = 1'b1;
        DRA: DC = 1'b1;
        DATA: DC = 1'b1;
        default: DC = 1'b0;
    endcase
end  
endmodule