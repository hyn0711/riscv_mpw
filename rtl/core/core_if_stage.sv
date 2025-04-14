
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
    output  logic   [XLEN-1:0]  pc_instr_o,
    input logic [XLEN-1:0]      pc_curr_imem_i,
   // output  logic   [XLEN-1:0]  out_pc_curr_o,

    // C extension 
    input                       ex_stall_i,
    input                       dma_stall_i,
    //output logic                instr_fetch_o, 

    input   [XLEN-1:0]          instr_i,            // from IMEM
    output logic [XLEN-1:0]     instr_o



);

    // Program counter
    logic [XLEN-1:0] pc_next;
    logic [XLEN-1:0] pc_plus_4;
    logic [XLEN-1:0] pc_branch_plus_4;

    logic [XLEN-1:0] out_pc_curr_o;
    logic [XLEN-1:0] pc_curr_imem;

    assign pc_plus_4 = pc_curr_o + 4;
    assign pc_branch_plus_4 = pc_branch_i + 4;

    assign pc_next = (branch_taken_i) ? pc_branch_plus_4 : pc_plus_4;

/*
    program_counter #(
        .XLEN       (XLEN),
        .RESET_PC   (RESET_PC)
    ) pc (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .pc_write_i (pc_write_i),
        .pc_next_i  (pc_next),
        .pc_curr_o  (pc_curr_o)
    );
*/

    prefetch_buffer_unit #(
        .ENTRY (3),
        .XLEN  (32),
        .RESET_PC (RESET_PC)
    ) pb (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),

        .branch_i       (branch_taken_i),
        .ex_stall_i     (ex_stall_i),
        .dma_stall_i    (dma_stall_i),

        .in_instr_i     (instr_i),              // from imem
        .pc_curr_imem_i (pc_curr_imem),

        .out_instr_o    (instr_o),
        .out_pc_curr_o  (out_pc_curr_o),

        .pc_write_i     (pc_write_i),
        .pc_next_i      (pc_next),
        .pc_curr_o      (pc_curr_o)

    );

    assign pc_instr_o = out_pc_curr_o;
    // --------------------------------------------------------
    // current instruction's pc output

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            //pc_instr_o <= '0;
            pc_curr_imem <= '0;
        end else begin
            //pc_instr_o <= out_pc_curr_o;
            pc_curr_imem <= pc_curr_imem_i;
        end
    end

/*
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (rst_ni == 1'b0) begin
            pc_instr_o <= '0;
        end else begin
            if (branch_taken_i) begin
                pc_instr_o <= pc_branch_i;
            end else begin
                pc_instr_o <= out_pc_curr_o; // 맞나.?
            end
        end
    end
*/

endmodule