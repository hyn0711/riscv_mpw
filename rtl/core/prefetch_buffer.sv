module prefetch_buffer #(
    parameter           ENTRY = 4,
    parameter           XLEN = 3,
    parameter           RESET_PC = 32'h1000_0000
) (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic                 branch_i,

    input logic [XLEN-1:0]      in_addr_i,
    input logic [XLEN-1:0]      in_instr_i,
    input logic                 in_nstall_i,

    // output port
    output logic [XLEN-1:0]     out_addr_o,
    output logic [XLEN-1:0]     out_instr_o,

    output logic                fetch_nstall_o,
    output logic                is_compressed_o,

    // program counter
    input logic                 pc_write_i,
    input logic [XLEN-1:0]      pc_next_i,
    output logic [XLEN-1:0]     pc_curr_o
);


    logic               fetch_ready;
    logic [XLEN-1:0]    out_addr;
    logic [XLEN-1:0]    out_instr;
    logic [XLEN-1:0]    in_addr;
    logic               in_valid;

    assign fetch_nstall_o = fetch_ready;
    assign out_addr_o = out_addr;
    assign out_instr_o = out_instr;
   
    fifo_unit #(
        .ENTRY (4),
        .XLEN (32),
        .RESET_PC(32'h1000_0000)
    ) if_fifo (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .in_addr_i(in_addr),
        .in_instr_i(in_instr_i),

        .in_nstall_i(in_nstall_i),
        .in_valid_i(in_valid),

        //.pop_req_i(1'b1),
        //.push_req_i(1'b1),

        .clear_i(branch_i),
        .fetch_ready_o(fetch_ready),

        .out_addr_o(out_addr),
        .out_instr_o(out_instr),

        .is_compressed_o(is_compressed_o)
    );

    //assign pc_write = pc_write_i && fetch_ready;



    // program counter
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pc_curr_o <= RESET_PC;
            in_addr <= RESET_PC;
            in_valid <= '0;
        end else begin
            in_addr <= in_addr_i;
            in_valid <= 1'b1;
            if (pc_write_i) begin
                pc_curr_o <= pc_next_i;
            end else begin
                pc_curr_o <= pc_curr_o;
            end
        end
    end





endmodule