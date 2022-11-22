// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

wire [7:0] in1,in2,in3,in4;
wire [5:0] in5;
wire [16:0] out;
assign {in5, in1, in2, in3, in4} = io_in[`MPRJ_IO_PADS-1:0];
assign io_out = {21'd0, out};

sop_ax_k16_axl4 u1 (.a(in1),.b(in2),.c(in3),.d(in4),.out(out));
endmodule
module sop_ax_k16_axl4(a,b,c,d,out);

input [7:0] a,b,c,d;

output [16:0] out;

wire [15:0] w1,w2;


prop_ax8_using_4bit_4ax u1(a,b,w1);
prop_ax8_using_4bit_4ax u2(a,b,w2);


//assign w1= a*b;  // 8bit mul1
//assign w2= c*d; // 8bit mul2

//assign out= w1 + w2; // 16 bit adder

axhrca_nek_rev_16 u3 (w1,w2,out);

endmodule

// 8 bit multiplier using 4 bit multipliers

module prop_ax8_using_4bit_4ax(a,b,c);
   
input [7:0]a;
input [7:0]b;
output [15:0]c;

wire [15:0]q0;	
wire [15:0]q1;	
wire [15:0]q2;
wire [15:0]q3;	
wire [15:0]c;
wire [7:0]temp1;
wire [11:0]temp2;
wire [11:0]temp3;
wire [11:0]temp4;
wire [7:0]q4;
wire [11:0]q5;
wire [11:0]q6;
// using 4 4x4 multipliers
prop_mult2_sdk z1(a[3:0],b[3:0],q0[7:0]);

prop_mult2_sdk z2(a[7:4],b[3:0],q1[7:0]);
//assign q1[7:0]=a[7:4]*b[3:0];
prop_mult2_sdk z3(a[3:0],b[7:4],q2[7:0]);
//assign q2[7:0]=b[7:4]*a[3:0];
prop_mult2_sdk z4(a[7:4],b[7:4],q3[7:0]);
//assign q3[7:0]=a[7:4]*b[7:4];
// stage 1 adders 
assign temp1 ={4'b0,q0[7:4]};
assign q4= temp1+q1[7:0];
//add_8_bit z5(q1[7:0],temp1,q4);
assign temp2 ={4'b0,q2[7:0]};
assign temp3 ={q3[7:0],4'b0};
assign q5=temp2+temp3;
//add_12_bit z6(temp2,temp3,q5);
assign temp4={4'b0,q4[7:0]};
// stage 2 adder
assign q6=temp4+q5;
//add_12_bit z7(temp4,q5,q6);
// fnal output assignment 
assign c[3:0]=q0[3:0];
assign c[15:4]=q6[11:0];

endmodule



module prop_mult2_sdk(A,B,out);
input [3:0] A,B;
output [7:0] out;
 wire [3:0] p0,p1,p2,p3;
 assign  p0 = A &{4{B[0]}};
 assign  p1 = A & {4{B[1]}};
 assign  p2 = A & {4{B[2]}};
 assign  p3 = A & {4{B[3]}};
  assign out[0]=p0[0];
 assign out[1]=p0[1]^p1[0];
 assign out[2]=p0[2]|p1[1]|p2[0];
 assign out[3]= p0[3]|p1[2]|p2[1]|p3[0];
 assign out[4]=p2[2]|p3[1]|p1[3];
 assign out[5]= p2[3]^p3[2];
 assign out[6]= p3[3];
 assign out[7]=p3[3]&p2[2];
 endmodule
 
 module axhrca_nek_rev_16(a,b,sum);
//parameter n=16;
//parameter l=8;
//parameter k=16;
input [15:0] a,b;

output [16:0] sum;
wire [7:1]cout;
wire cin;
assign sum[0]=a[0]^b[0];
assign cin=a[0]&b[0];
ascfa4v2 u1 (a[1],b[1],cin,sum[1],cout[1]);
genvar i;
generate
    for(i=2;i<=(7);i=i+1) begin
        ascfa4v2 u2 (a[i],b[i],cout[i-1],sum[i],cout[i]);
    end
endgenerate
genvar j;
generate 
    for(j=8; j<=(15);j=j+1) begin
    ascfa4v1 u3 (a[j],b[j],sum[j]);
    end
endgenerate
assign sum[16]=a[15] & b[15];
endmodule

module ascfa4v1(a,b,sum);
input a,b;
output sum;
wire w3=a|b;
assign sum= w3;

endmodule

module ascfa4v2(a,b,cin,sum,cout);
input a,b,cin;
output sum,cout;
wire w3=a|b;
assign sum= w3|cin;
assign cout= a&b;
endmodule
 

`default_nettype wire
