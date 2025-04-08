/*

Compressed instruction decoder

16-bit instruction -> 32-bit instruction
Decompression

*/

module compressed_decoder (
    input                       clk_i,
    input                       rst_ni,
    input                       valid_i,            // 필요한가...?
    input  logic [31:0]         instr_i,
    output logic [31:0]         instr_o,
    output logic                is_compressed_o,
    output logic                illegal_instr_o         // 얘도 뭔 역할이여
);


  ////////////////////////
  // Compressed decoder //
  ////////////////////////

  always_comb begin
    instr_o         = instr_i;      // Normal 32-bit instruction
    illegal_instr_o = 1'b0;

    unique case (instr_i[1:0])
      //C0
      2'b00: begin
        unique case (instr_i[15:13])