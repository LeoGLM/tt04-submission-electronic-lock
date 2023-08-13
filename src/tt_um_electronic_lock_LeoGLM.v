module tt_um_electronic_lock_LeoGLM #( parameter MAX_COUNT = 10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset 
);
    
    wire [3:0] userinput;
    wire       lock;
    
    assign userinput =       ui_in [3:0];     //1111: no input, 1110: set_passcode, 0001-1001: 1-0 ；1101:cancel
    assign uo_out[0] =       lock  ;
    
    /*assign uo_out[1] = 1'b0;
    assign uo_out[2] = 1'b0;
    assign uo_out[3] = 1'b0;
    assign uo_out[4] = 1'b0;
    assign uo_out[5] = 1'b0;
    assign uo_out[6] = 1'b0;
    assign uo_out[7] = 1'b0;*/

    //output [3:0]states,
    //output [2:0]counters

    parameter IDLE        = 4'd0;
    parameter correct1    = 4'd1;
    parameter correct2    = 4'd2;
    parameter correct3    = 4'd3;
    parameter unlocked    = 4'd4;
    parameter wrong       = 4'd5;
    parameter digit1      = 4'd6;
    parameter digit2      = 4'd7;
    parameter digit3      = 4'd8;
    parameter digit4      = 4'd9;

    reg [3:0] pc1;
    reg [3:0] pc2;
    reg [3:0] pc3;
    reg [3:0] pc4;
    reg [3:0] state;
    reg [3:0] nextstate;
    reg [2:0] counter;
    reg unlocked_reg;
    
    
    always@(posedge clk) begin
        if (!rst_n) begin
            state        <= IDLE;
            pc1          <= 4'b0000;
            pc2          <= 4'b0000;
            pc3          <= 4'b0000;
            pc4          <= 4'b0000;
            counter      <= 0;
            unlocked_reg <= 0;
        end
        else begin   
            if (counter==5) begin
                unlocked_reg <= 0;
                counter      <= 0;
            end
            else if (unlocked_reg == 1) 
                counter      <= counter+1;

            if (counter==5 && state == unlocked)
                state        <= IDLE;
            else
                state        <= nextstate;
        end
    end
    always@(userinput,counter) begin
        if (userinput == 4'b1101)
            nextstate = IDLE;
        else if (userinput == 4'b1111)
            nextstate = state;
        else begin
            case(state)
                IDLE : begin
                    if (userinput == pc1)
                        nextstate = correct1;
                    else 
                        nextstate = wrong;
                end
                correct1 : begin
                    if (userinput == pc2)
                        nextstate = correct2;
                    else 
                        nextstate = wrong;
                end
                correct2 : begin
                    if (userinput == pc3)
                        nextstate = correct3;
                    else 
                        nextstate = wrong;
                end
                correct3 : begin
                    if (userinput == pc4) begin
                        nextstate    = unlocked;
                        unlocked_reg = 1;
                    end
                    else 
                        nextstate = wrong; 
                end
                wrong :  begin
                    nextstate = wrong;
                end
                unlocked : begin
                    if (userinput == 4'b1110) 
                        nextstate = digit1;
                    else
                        nextstate = unlocked;
                end
                digit1 : begin
                    pc1       = userinput;
                    nextstate = digit2;
                end
                digit2 : begin
                    pc2       = userinput;
                    nextstate = digit3;
                end
                digit3 : begin
                    pc3       = userinput;
                    nextstate = digit4;
                end
                digit4 : begin
                    pc4       = userinput;
                    nextstate = IDLE;
                end
                default : nextstate = IDLE;
            endcase
        end
    end
 
    assign lock = unlocked_reg;
    //assign states = state;
    //assign counters = counter;
endmodule
