`include "include.v"
module data_flow_handler #(
    parameter integer NUM_NEURON_LAYER = 30
)
(
    input wire clk,
    input wire reset,
    input wire o1_valid_1bit,
    input wire [NUM_NEURON_LAYER*`dataWidth-1:0] x_out,
    output reg data_out_valid,
    output reg [`dataWidth-1:0] out_data
);
reg state;
integer count;
reg [NUM_NEURON_LAYER*`dataWidth-1:0] holdData;
localparam IDLE= 'd0,
            SEND='d1;
            
always @(posedge clk)
begin
    if(reset)
    begin
        state <= IDLE;
        count <= 0;
        data_out_valid <=0;
        out_data <= 0;
        holdData <= 0;
    end
    else
    begin
        case(state)
            IDLE: begin
                count <= 0;
                data_out_valid <=0;
                if (o1_valid_1bit== 1'b1)
                begin
                    holdData <= x_out;
                    state <= SEND;
                end
            end
            SEND: begin
                out_data <= holdData[`dataWidth-1:0];
                holdData <= holdData>>`dataWidth;
                count <= count +1;
                data_out_valid <= 1;
                if (count == NUM_NEURON_LAYER)
                begin
                    state <= IDLE;
                    data_out_valid <= 0;
                end
            end
        endcase
    end
end
endmodule
