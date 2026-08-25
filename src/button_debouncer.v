module buttonDebouncer(
    input d, CLK, RES,
    output reg sd = 1'b0
);

reg [18:0] counter = 19'd0;

reg da = 1'b0, db = 1'b0;

always @(negedge CLK or posedge RES) begin
    if(RES) begin
        sd <= 1'b0;
        da <= 1'b0;
        db <= 1'b0;
        counter <= 19'd0;
    end else begin
        da <= d;
        db <= da;

        if(sd != db) begin
            if(counter >= 19'd270000) begin
                sd <= db;
                counter <= 19'd0;
            end else counter <= counter + 19'd1;
        end else counter <= 19'd0;
    end
end

endmodule