module prefetch_buffer_unit #(
    parameter                   ENTRY = 3,
    parameter                   XLEN = 32,
    parameter                   RESET_PC = 32'h1000_0000
) (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic                 branch_i,
    input logic                 ex_stall_i,
    input logic                 dma_stall_i,

    input logic [31:0]          in_instr_i,
    input logic [31:0]          pc_curr_imem_i,

    output logic [31:0]         out_instr_o,  
    output logic [31:0]         out_pc_curr_o,

    //output logic                fetch_req_o,

    // pc
    input logic                 pc_write_i,
    input logic [XLEN-1:0]      pc_next_i,
    output logic [XLEN-1:0]     pc_curr_o       

);

    logic           clear;
    logic           push_req;
    logic           pop_req;
    logic           fetch_req;

    assign clear = branch_i | ex_stall_i | dma_stall_i;
    assign push_req = ~branch_i & ~ex_stall_i & ~dma_stall_i;
    assign pop_req = ~branch_i & ~ex_stall_i & ~dma_stall_i;


    logic [XLEN-1:0]    pc_curr_instr;
    assign pc_curr_instr = pc_curr_imem_i;

/*
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pc_curr_instr <= '0;
        end else begin
            pc_curr_instr <= pc_curr_o;
        end
    end
*/

    //assign fetch_req_o = fetch_req;


    fifo_unit_new #(
        .ENTRY (3)
    ) fifo_if (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .clear_i(clear),

        .in_instr_i(in_instr_i),
        .in_pc_i(pc_curr_instr),

        .push_req_i(push_req),
        .pop_req_i(pop_req),

        .out_instr_o(out_instr_o),
        .out_pc_curr_o(out_pc_curr_o),

        .fetch_req_o(fetch_req)
    );

    logic           pc_write;
    assign          pc_write = pc_write_i & fetch_req;

    // program counter
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (rst_ni == '0) begin
            pc_curr_o <= RESET_PC;
        end else begin
            if (pc_write) begin
                pc_curr_o <= pc_next_i;
            end else begin
                pc_curr_o <= pc_curr_o;
            end
        end
    end

endmodule