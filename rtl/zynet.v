`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2019 20:57:54
// Design Name: 
// Module Name: top_layer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "include.v"

module zyNet #(
    parameter integer C_S_AXI_DATA_WIDTH    = 32,
    parameter integer C_S_AXI_ADDR_WIDTH    = 5
)
(
    //Clock and Reset
    input                                   s_axi_aclk,
    input                                   s_axi_aresetn,
    //AXI Stream interface
    input [`dataWidth-1:0]                  axis_in_data,
    input                                   axis_in_data_valid,
    output                                  axis_in_data_ready,
    //AXI Lite Interface
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0]   s_axi_awaddr,
    input wire [2 : 0]                      s_axi_awprot,
    input wire                              s_axi_awvalid,
    output wire                             s_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0]   s_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
    input wire                              s_axi_wvalid,
    output wire                             s_axi_wready,
    output wire [1 : 0]                     s_axi_bresp,
    output wire                             s_axi_bvalid,
    input wire                              s_axi_bready,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0]   s_axi_araddr,
    input wire [2 : 0]                      s_axi_arprot,
    input wire                              s_axi_arvalid,
    output wire                             s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]  s_axi_rdata,
    output wire [1 : 0]                     s_axi_rresp,
    output wire                             s_axi_rvalid,
    input wire                              s_axi_rready,
    //Interrupt interface
    output wire                             intr
);


wire [31:0]  config_layer_num;
wire [31:0]  config_neuron_num;
wire [31:0] weightValue;
wire [31:0] biasValue;
wire [31:0] out;
wire out_valid;
wire weightValid;
wire biasValid;
wire axi_rd_en;
wire [31:0] axi_rd_data;
wire softReset;

assign intr = out_valid;
assign axis_in_data_ready = 1'b1;

axi_lite_wrapper # ( 
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) alw (
    .S_AXI_ACLK(s_axi_aclk),
    .S_AXI_ARESETN(s_axi_aresetn),
    .S_AXI_AWADDR(s_axi_awaddr),
    .S_AXI_AWPROT(s_axi_awprot),
    .S_AXI_AWVALID(s_axi_awvalid),
    .S_AXI_AWREADY(s_axi_awready),
    .S_AXI_WDATA(s_axi_wdata),
    .S_AXI_WSTRB(s_axi_wstrb),
    .S_AXI_WVALID(s_axi_wvalid),
    .S_AXI_WREADY(s_axi_wready),
    .S_AXI_BRESP(s_axi_bresp),
    .S_AXI_BVALID(s_axi_bvalid),
    .S_AXI_BREADY(s_axi_bready),
    .S_AXI_ARADDR(s_axi_araddr),
    .S_AXI_ARPROT(s_axi_arprot),
    .S_AXI_ARVALID(s_axi_arvalid),
    .S_AXI_ARREADY(s_axi_arready),
    .S_AXI_RDATA(s_axi_rdata),
    .S_AXI_RRESP(s_axi_rresp),
    .S_AXI_RVALID(s_axi_rvalid),
    .S_AXI_RREADY(s_axi_rready),
    .layerNumber(config_layer_num),
    .neuronNumber(config_neuron_num),
    .weightValue(weightValue),
    .weightValid(weightValid),
    .biasValid(biasValid),
    .biasValue(biasValue),
    .nnOut_valid(out_valid),
    .nnOut(out),
    .axi_rd_en(axi_rd_en),
    .axi_rd_data(axi_rd_data),
    .softReset(softReset)
);

wire reset;

assign reset = ~s_axi_aresetn|softReset;

localparam IDLE = 'd0,
           SEND = 'd1;
wire [`numNeuronLayer1-1:0] o1_valid;
wire [`numNeuronLayer1*`dataWidth-1:0] x1_out;
//reg [`numNeuronLayer1*`dataWidth-1:0] holdData_1;
//reg [`dataWidth-1:0] out_data_1;
//reg data_out_valid_1;
wire [`dataWidth-1:0] out_data_1;
wire data_out_valid_1;

Layer #(.NN(`numNeuronLayer1),.numWeight(`numWeightLayer1),.dataWidth(`dataWidth),.layerNum(1),.sigmoidSize(`sigmoidSize),.weightIntWidth(`weightIntWidth),.actType(`Layer1ActType)) l1(
	.clk(s_axi_aclk),
	.rst(reset),
	.weightValid(weightValid),
	.biasValid(biasValid),
	.weightValue(weightValue),
	.biasValue(biasValue),
	.config_layer_num(config_layer_num),
	.config_neuron_num(config_neuron_num),
	.x_valid(axis_in_data_valid),
	.x_in(axis_in_data),
	.o_valid(o1_valid),
	.x_out(x1_out)
);

//State machine for data pipelining
data_flow_handler #(.NUM_NEURON_LAYER(`numNeuronLayer1))
dfl_1(
    .clk(s_axi_aclk),
    .reset(reset),
    .o1_valid_1bit(o1_valid[0]),
    .x_out(x1_out),
    .data_out_valid(data_out_valid_1),
    .out_data(out_data_1)
    );

wire [`numNeuronLayer2-1:0] o2_valid;
wire [`numNeuronLayer2*`dataWidth-1:0] x2_out;
wire [`dataWidth-1:0] out_data_2;
wire data_out_valid_2;

Layer #(.NN(`numNeuronLayer2),.numWeight(`numWeightLayer2),.dataWidth(`dataWidth),.layerNum(2),.sigmoidSize(`sigmoidSize),.weightIntWidth(`weightIntWidth),.actType(`Layer2ActType)) l2(
	.clk(s_axi_aclk),
	.rst(reset),
	.weightValid(weightValid),
	.biasValid(biasValid),
	.weightValue(weightValue),
	.biasValue(biasValue),
	.config_layer_num(config_layer_num),
	.config_neuron_num(config_neuron_num),
	.x_valid(data_out_valid_1),
	.x_in(out_data_1),
	.o_valid(o2_valid),
	.x_out(x2_out)
);
//State machine for data pipelining
data_flow_handler #(.NUM_NEURON_LAYER(`numNeuronLayer2))
dfl_2(
    .clk(s_axi_aclk),
    .reset(reset),
    .o1_valid_1bit(o2_valid[0]),
    .x_out(x2_out),
    .data_out_valid(data_out_valid_2),
    .out_data(out_data_2)
    );

wire [`numNeuronLayer3-1:0] o3_valid;
wire [`numNeuronLayer3*`dataWidth-1:0] x3_out;
wire [`dataWidth-1:0] out_data_3;
wire data_out_valid_3;

Layer #(.NN(`numNeuronLayer3),.numWeight(`numWeightLayer3),.dataWidth(`dataWidth),.layerNum(3),.sigmoidSize(`sigmoidSize),.weightIntWidth(`weightIntWidth),.actType(`Layer3ActType)) l3(
	.clk(s_axi_aclk),
	.rst(reset),
	.weightValid(weightValid),
	.biasValid(biasValid),
	.weightValue(weightValue),
	.biasValue(biasValue),
	.config_layer_num(config_layer_num),
	.config_neuron_num(config_neuron_num),
	.x_valid(data_out_valid_2),
	.x_in(out_data_2),
	.o_valid(o3_valid),
	.x_out(x3_out)
);

//State machine for data pipelining
data_flow_handler #(.NUM_NEURON_LAYER(`numNeuronLayer3))
dfl_3(
    .clk(s_axi_aclk),
    .reset(reset),
    .o1_valid_1bit(o3_valid[0]),
    .x_out(x3_out),
    .data_out_valid(data_out_valid_3),
    .out_data(out_data_3)
    );

wire [`numNeuronLayer4-1:0] o4_valid;
wire [`numNeuronLayer4*`dataWidth-1:0] x4_out;
wire [`dataWidth-1:0] out_data_4;
wire data_out_valid_4;

Layer #(.NN(`numNeuronLayer4),.numWeight(`numWeightLayer4),.dataWidth(`dataWidth),.layerNum(4),.sigmoidSize(`sigmoidSize),.weightIntWidth(`weightIntWidth),.actType(`Layer4ActType)) l4(
	.clk(s_axi_aclk),
	.rst(reset),
	.weightValid(weightValid),
	.biasValid(biasValid),
	.weightValue(weightValue),
	.biasValue(biasValue),
	.config_layer_num(config_layer_num),
	.config_neuron_num(config_neuron_num),
	.x_valid(data_out_valid_3),
	.x_in(out_data_3),
	.o_valid(o4_valid),
	.x_out(x4_out)
);
//State machine for data pipelining
data_flow_handler #(.NUM_NEURON_LAYER(`numNeuronLayer4))
dfl_4(
    .clk(s_axi_aclk),
    .reset(reset),
    .o1_valid_1bit(o4_valid[0]),
    .x_out(x4_out),
    .data_out_valid(data_out_valid_4),
    .out_data(out_data_4)
    );


reg [`numNeuronLayer4*`dataWidth-1:0] holdData_5;
assign axi_rd_data = holdData_5[`dataWidth-1:0];

always @(posedge s_axi_aclk)
    begin
        if (o4_valid[0] == 1'b1)
            holdData_5 <= x4_out;
        else if(axi_rd_en)
        begin
            holdData_5 <= holdData_5>>`dataWidth;
        end
    end


maxFinder #(.numInput(`numNeuronLayer4),.inputWidth(`dataWidth))
    mFind(
        .i_clk(s_axi_aclk),
        .reset(reset),
        .i_data(x4_out),
        .i_valid(o4_valid),
        .o_data(out),
        .o_data_valid(out_valid)
    );
endmodule