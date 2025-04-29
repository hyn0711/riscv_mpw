module fifo_unit #(
    parameter           ENTRY = 3,
    parameter           XLEN = 32,
    parameter           RESET_PC = 32'h1000_0000
) (
    input logic                 clk_i,
    input logic                 rst_ni,

    // input port 
    input logic [XLEN-1:0]      in_addr_i,
    input logic [XLEN-1:0]      in_instr_i,

    input logic                 in_nstall_i,
    input logic                 in_valid_i,
    // signal
    //input logic                 pop_req_i,
    //input logic                 push_req_i,

    // control signal
    input logic                 clear_i,
    output logic                fetch_ready_o,          //request the fetch

    // output port
    output logic [XLEN-1:0]      out_addr_o,
    output logic [XLEN-1:0]      out_instr_o,

    output logic                 is_compressed_o
);

    //debug
    logic [XLEN-1:0] debug_addr_q_0, debug_addr_q_1, debug_addr_q_2;
    logic [XLEN-1:0] debug_instr_q_0, debug_instr_q_1, debug_instr_q_2;
    logic debug_valid_q_0;

    assign debug_addr_q_0 = addr_q[0];
    assign debug_addr_q_1 = addr_q[1];
    assign debug_addr_q_2 = addr_q[2];

    assign debug_instr_q_0 = instr_q[0];
    assign debug_instr_q_1 = instr_q[1];
    assign debug_instr_q_2 = instr_q[2];

    assign debug_valid_q_0 = valid_q[0];


    logic [ENTRY-1:0] valid_q, valid_d;
    logic [XLEN-1:0] instr_q[ENTRY-1:0], instr_d[ENTRY-1:0];
    logic [XLEN-1:0] addr_q[ENTRY-1:0], addr_d[ENTRY-1:0];
    logic [XLEN-1:0] instr_q_0, instr_q_1, addr_q_0;
    logic [XLEN-1:0] out_instr_unaligned;

    logic unaligned_is_compressed, aligned_is_compressed;
    logic instr_is_unaligned, instr_is_compressed;
    logic [1:0] unaligned_compressed;

    assign instr_q_0 = instr_q[0];
    assign instr_q_1 = instr_q[1];
    assign addr_q_0 = addr_q[0];

    assign out_instr_unaligned = {instr_q_1[15:0],instr_q_0[31:16]};

    // check the aligned
    assign instr_is_unaligned = addr_q_0[1];

    // check the compression
    assign instr_is_compressed = instr_is_unaligned ?
                                 (instr_q_0[17:16] != 2'b11) :
                                 (instr_q_0[1:0] != 2'b11);

    assign is_compressed_o = instr_is_compressed;
    // assign unaligned_is_compressed = instr_q_0[17:16] != 2'b11;
    // assign aligned_is_compressed = instr_q_0[1:0] != 2'b11;

    assign unaligned_compressed = {instr_is_unaligned, instr_is_compressed};

    logic push_req;

    assign push_req = ~valid_q[0] || ~valid_q[1] || ~valid_q[2] || fetch_ready_o;

    // input
    always_comb begin
        if (clear_i) begin
            addr_d[2] = '0;
            instr_d[2] = '0;
            valid_d[2] = '0;
        end else begin
            if (push_req) begin
                addr_d[2] = in_addr_i;
                instr_d[2] = in_instr_i;
                valid_d[2] = 1'b1;
            end else begin
                addr_d[2] = addr_q[2];
                instr_d[2] = instr_q[2];
                valid_d[2] = valid_q[2];
            end
        end
    end

    // fifo entry
    always_comb begin
        fetch_ready_o = 1'b1;
        if (clear_i) begin
            // addr
            addr_d[1] = '0;
            addr_d[0] = '0;
            // instr
            instr_d[1] = '0;
            instr_d[0] = '0;
            // valid
            valid_d[1] = '0;
            valid_d[0] = '0;
        end else begin
            if (valid_q[0]) begin
                case (unaligned_compressed)
                2'b00: begin            // aligned + uncompressed
                    // addr
                    addr_d[1] = addr_q[2];
                    addr_d[0] = addr_q[0]+32'h4;
                    // instr
                    instr_d[1] = instr_q[2];
                    instr_d[0] = instr_q[1];
                    // valid
                    valid_d[1] = valid_q[2];
                    valid_d[0] = valid_q[1];

                    fetch_ready_o = 1'b1;
                end
                2'b01: begin            // aligned + compressed
                    // addr
                    addr_d[1] = addr_q[1];
                    addr_d[0] = addr_q[0] + 32'h2;      // next instruction's address = address + 2
                    // instr
                    instr_d[1] = instr_q[1];
                    instr_d[0] = instr_q[0];
                    // valid
                    valid_d[1] = valid_q[1];
                    valid_d[0] = valid_q[0];

                    fetch_ready_o = 1'b0;
                end
                2'b10: begin            // unaligned + uncompressed
                    // addr
                    addr_d[1] = addr_q[2];
                    addr_d[0] = addr_q[0] + 32'h4;
                    // instr
                    instr_d[1] = instr_q[2];
                    instr_d[0] = instr_q[1];
                    // valid
                    valid_d[1] = valid_q[2];
                    valid_d[0] = valid_q[1];

                    fetch_ready_o = 1'b1;
                end
                2'b11: begin            // unaligned + compressed
                    // addr 
                    addr_d[1] = addr_q[2];
                    addr_d[0] = addr_q[0] + 32'h2;
                    // instr
                    instr_d[1] = instr_q[2];
                    instr_d[0] = instr_q[1];
                    // valid
                    valid_d[1] = valid_q[2];
                    valid_d[0] = valid_q[1];

                    fetch_ready_o = 1'b1;
                end
                default: begin
                    // addr 
                    addr_d[1] = addr_q[1];
                    addr_d[0] = addr_q[0];
                    // instr
                    instr_d[1] = instr_q[1];
                    instr_d[0] = instr_q[0];
                    // valid
                    valid_d[1] = valid_q[1];
                    valid_d[0] = valid_q[0];

                    fetch_ready_o = 1'b1;
                end
                endcase
            end else begin      // valid_q[0] = 0 : shift
                // addr
                addr_d[1] = addr_q[2];
                addr_d[0] = addr_q[1];
                // instr
                instr_d[1] = instr_q[2];
                instr_d[0] = instr_q[1];
                // valid
                valid_d[1] = valid_q[2];
                valid_d[0] = valid_q[1];
            end
        end
    end

    assign pop_req = in_nstall_i;

    // output
    always_comb begin
        if (pop_req && valid_q[0]) begin
            case (instr_is_unaligned) 
            1'b0: begin         // aligned
                out_addr_o = addr_q[0];
                out_instr_o = instr_q[0];
            end
            1'b1: begin
                out_addr_o = addr_q[0];
                out_instr_o = out_instr_unaligned;
            end
            default: begin
                out_addr_o = '0;
                out_instr_o = '0;
            end
            endcase
        end else begin
            out_addr_o = '0;
            out_instr_o = '0;
        end
    end

    //register
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < ENTRY; i++) begin
                addr_q[i] = '0;
                instr_q[i] = '0;
                valid_q[i] = '0;
            end
        end else if (in_valid_i) begin
            for (int i = 0; i < ENTRY; i++) begin
                addr_q[i] = addr_d[i];
                instr_q[i] = instr_d[i];
                valid_q[i] = valid_d[i];
            end
        end else begin
            for (int i = 0; i < ENTRY; i++) begin
                addr_q[i] = '0;
                instr_q[i] = '0;
                valid_q[i] = '0;
            end
        end
    end


endmodule




