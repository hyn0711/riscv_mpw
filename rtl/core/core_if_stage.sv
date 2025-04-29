
module core_if_stage #(
    parameter XLEN      = 32,
    parameter RESET_PC  = 32'h1000_0000
) (
    input                       clk_i,
    input                       rst_ni,
    input                       pc_write_i,
    input                       branch_taken_i,
    input   [XLEN-1:0]          pc_branch_i,

    output  logic   [XLEN-1:0]  pc_curr_o,

    //output logic                instr_fetch_o, 

    input logic [XLEN-1:0]      in_addr_i,
    input logic [XLEN-1:0]      in_instr_i,  

    input logic                 in_nstall_i,

    output logic [XLEN-1:0]     out_addr_o,
    output logic [XLEN-1:0]     out_instr_o,

    output logic                fetch_nstall_o,
    output logic                is_compressed_o
);

    // Program counter
    logic [XLEN-1:0] pc_next;
    logic [XLEN-1:0] pc_plus_4;
    logic [XLEN-1:0] pc_branch_plus_4;

    assign pc_plus_4 = pc_curr_o + 4;
    assign pc_branch_plus_4 = pc_branch_i + 4;

    assign pc_next = (branch_taken_i) ? pc_branch_plus_4 : pc_plus_4;


    // output port
    logic [XLEN-1:0] out_addr;
    logic [XLEN-1:0] out_instr;
    assign out_addr_o = out_addr;
    assign out_instr_o = out_instr;

    prefetch_buffer #(
        .ENTRY (4),
        .XLEN  (32),
        .RESET_PC (RESET_PC)
    ) pb (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),

        .branch_i       (branch_taken_i),

        .in_addr_i      (in_addr_i),
        .in_instr_i     (in_instr_i),
        .in_nstall_i    (in_nstall_i),

        .out_addr_o     (out_addr),
        .out_instr_o    (out_instr),

        .fetch_nstall_o (fetch_nstall_o),
        .is_compressed_o(is_compressed_o),

        .pc_write_i     (pc_write_i),
        .pc_next_i      (pc_next),
        .pc_curr_o      (pc_curr_o)

    );



endmodule