module pongEngine (
    input RES, CLK, cont,
            d1, d2, u1, u2,
    
    input [7:0] x_cord, y_cord,
    
    output wire draw
);

reg clk_phase = 1'b0;

always @(negedge CLK) begin
    if(RES) clk_phase <= 1'b0;
    else clk_phase <= ~clk_phase;
end

reg [7:0] p1_y = 8'd70,
          p2_y = 8'd70,
          b_x = 8'd64, b_y = 8'd80;

parameter [7:0] p1_x = 8'd5, p2_x = 8'd118;

// ball physics
reg [1:0] ball_dir = 2'b00; // [0] - 0 for down and 1 for up, [1] - 0 for left and 1 for right
reg [3:0] ball_h_abs_velocity = 4'd1, ball_v_abs_velocity = 4'd2;

reg [3:0] p1_score = 4'd0, p2_score = 4'd0;



// the size of the bodies
parameter [4:0] p_height = 5'd25, p_width = 5'd5;
parameter [2:0] b_size = 3'd5;

// states
parameter [1:0] IDLE = 2'd0,
                GAME = 2'd1,
                FINISH = 2'd2;

reg [1:0] current_state = IDLE, next_state;

// clk logic
always @(negedge CLK or posedge RES) begin
    if(RES) begin
        p1_score <= 4'd0;
        p2_score <= 4'd0;
        p1_y <= 8'd70;
        p2_y <= 8'd70;
        b_x <= 8'd64;
        b_y <= 8'd80;
        current_state <= IDLE;
    end else if (clk_phase) begin
        current_state <= next_state;
        if(cont) begin
            // bats updating
            if (d1 && p1_y < 8'd160 - p_height) p1_y <= p1_y + 8'd2;
            else if (u1 && p1_y > 8'd1) p1_y <= p1_y - 8'd2;
            if (d2 && p2_y < 8'd160 - p_height) p2_y <= p2_y + 8'd2;
            else if (u2 && p2_y > 8'd1) p2_y <= p2_y - 8'd2;

        if(current_state == GAME) begin
            //checking for collision
            // with bats
            if (ball_dir[0]) begin
                if (b_x < p1_x + {3'd0, p_width} + 8'd1 && b_y > p1_y - b_size && b_y < p1_y + p_height) ball_dir[0] <= 1'b0;
                else b_x <= b_x - {4'd0 , ball_v_abs_velocity};
            end else begin
                if (b_x > p2_x - {3'd0, p_width} - 8'd2 && b_y > p2_y - b_size && b_y < p2_y + p_height) begin
                    ball_dir[0] <= 1'b1;
                    if(ball_v_abs_velocity < 4'd5) ball_v_abs_velocity <= ball_v_abs_velocity + 4'd1;
                end
                else b_x <= b_x + {4'd0 , ball_v_abs_velocity};
            end

            //with walls
            if(ball_dir[1]) begin
                if (b_y >= 8'd157) ball_dir[1] <= 1'b0;
                else b_y <= b_y + {4'd0 , ball_h_abs_velocity};
            end else begin
                if (b_y <= 8'd3) ball_dir[1] <= 1'b1;
                else b_y <= b_y - {4'd0 , ball_h_abs_velocity};
            end

            if (b_x < 8'd3 || b_x > 8'd125) begin
                p1_y <= 8'd70;
                p2_y <= 8'd70;
                b_x <= 8'd64;
                b_y <= 8'd80;
                ball_dir <= 2'b00;
                ball_v_abs_velocity <= 4'd2;
                current_state <= IDLE;
            end 
        end

        end else begin
            p1_y <= p1_y;
            p2_y <= p2_y;
        end
        
        p1_score <= p1_score;
        p2_score <= p2_score;
        
        b_x <= b_x;
        b_y <= b_y;
    end
end


// state logic
always @(*) begin
    case(current_state)
        IDLE: next_state = (u1 || d1 || u2 || d2) ? GAME : IDLE;
        GAME: next_state = (p1_score >= 4'd10 || p2_score >= 4'd10) ? FINISH : GAME;
        FINISH: next_state = FINISH;
        default: next_state = IDLE;
    endcase
end

// output logic


// drawing seq
wire draw_p1 = (x_cord >= p1_x && x_cord < (p1_x + p_width) && y_cord >= p1_y && y_cord < (p1_y + p_height));
wire draw_p2 = (x_cord >= p2_x && x_cord < (p2_x + p_width) && y_cord >= p2_y && y_cord < (p2_y + p_height));
wire draw_p3 = (x_cord >= b_x && x_cord < (b_x + b_size) && y_cord >= b_y && y_cord < (b_y + b_size)); 

assign draw = draw_p1 | draw_p2 | draw_p3;
    
endmodule