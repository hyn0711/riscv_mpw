module fifo_unit_new #(
    parameter               ENTRY = 3,
    parameter               RESET_PC = 32'h1000_0000             
) (
    input logic             clk_i,
    input logic             rst_ni,

    input logic             clear_i,

    input logic [31:0]      in_instr_i,
    input logic [31:0]      in_pc_i,

    input logic             push_req_i,
    input logic             pop_req_i,

    output logic [31:0]     out_instr_o,
    output logic [31:0]     out_pc_curr_o,    

    output logic            fetch_req_o
);

    // debug _ fifo entry
    logic [31:0] debug_fifo_entry_0_q;
    logic [31:0] debug_fifo_entry_2_q;
    logic [31:0] debug_fifo_entry_1_q;
    logic [31:0] debug_fifo_entry_0_d;
    logic [31:0] debug_fifo_entry_2_d;
    logic [31:0] debug_fifo_entry_1_d;

    assign debug_fifo_entry_0_q = fifo_entry_q[0];
    assign debug_fifo_entry_1_q = fifo_entry_q[1];
    assign debug_fifo_entry_2_q = fifo_entry_q[2];
    assign debug_fifo_entry_0_d = fifo_entry_d[0];
    assign debug_fifo_entry_1_d = fifo_entry_d[1];
    assign debug_fifo_entry_2_d = fifo_entry_d[2];

    logic [31:0] debug_fifo_pc_0_q;
    logic [31:0] debug_fifo_pc_2_q;
    logic [31:0] debug_fifo_pc_1_q;
    logic [31:0] debug_fifo_pc_0_d;
    logic [31:0] debug_fifo_pc_2_d;
    logic [31:0] debug_fifo_pc_1_d;

    assign debug_fifo_pc_0_q = fifo_pc_q[0];
    assign debug_fifo_pc_1_q = fifo_pc_q[1];
    assign debug_fifo_pc_2_q = fifo_pc_q[2];
    assign debug_fifo_pc_0_d = fifo_pc_d[0];
    assign debug_fifo_pc_1_d = fifo_pc_d[1];
    assign debug_fifo_pc_2_d = fifo_pc_d[2];


    // debug_ valid
    logic valid_q_0;
    logic valid_q_1;
    logic valid_q_2;
    logic valid_q_3;
    logic valid_q_4;
    logic valid_q_5;

    assign valid_q_0 = valid_q[0];
    assign valid_q_1 = valid_q[1];
    assign valid_q_2 = valid_q[2];
    assign valid_q_3 = valid_q[3];
    assign valid_q_4 = valid_q[4];
    assign valid_q_5 = valid_q[5];

    logic valid_d_0;
    logic valid_d_1;
    logic valid_d_2;
    logic valid_d_3;
    logic valid_d_4;
    logic valid_d_5;

    assign valid_d_0 = valid_d[0];
    assign valid_d_1 = valid_d[1];
    assign valid_d_2 = valid_d[2];
    assign valid_d_3 = valid_d[3];
    assign valid_d_4 = valid_d[4];
    assign valid_d_5 = valid_d[5];



    logic           valid_d[2*ENTRY-1:0];        
    logic           valid_q[2*ENTRY-1:0];       
    logic [31:0]    fifo_entry_d[ENTRY-1:0];
    logic [31:0]    fifo_entry_q[ENTRY-1:0];

    logic [31:0]    fifo_pc_d[ENTRY-1:0];
    logic [31:0]    fifo_pc_q[ENTRY-1:0];


    logic [1:0]     check_compressed;
    logic           instr_compressed;

    logic           pop_req_q;
    logic           pop_req_d;

    logic [31:0]    out_instr;
    logic [31:0]    out_pc;

    logic [2:0]     clear_push_pop;

    logic pop_req;
    logic push_req;

    assign pop_req = pop_req_i && (valid_q[0] || valid_q[1]);

    assign clear_push_pop = {clear_i, push_req_i, pop_req};

    always_comb begin
        for (int i = 0; i < (2*ENTRY); i++) begin
            valid_d[i] = '0;
        end
        for (int j = 0; j < (ENTRY); j++) begin
            fifo_entry_d[j] = '0;
            fifo_pc_d[j] = '0;
        end
        case (clear_push_pop) 
            3'b000: begin           //IDLE
                for (int i = 0; i < (2*ENTRY); i++) begin
                    valid_d[i] = valid_q[i];
                end
                for (int j = 0; j < (ENTRY); j++) begin
                    fifo_entry_d[j] = fifo_entry_q[j];
                    fifo_pc_d[j] = fifo_pc_q[j];
                end
                pop_req_d = 1'b0;
                fetch_req_o = 1'b0;
            end
            3'b001: begin           // pop, not push //16b?
                for (int i = 1; i < (2*ENTRY); i++) begin
                    valid_d[i] = valid_q[i];
                end
                valid_d[0] = '0;
                for (int j = 0; j < (ENTRY); j++) begin
                    fifo_entry_d[j] = fifo_entry_q[j];
                    fifo_pc_d[j] = fifo_pc_q[j];
                end
                pop_req_d = 1'b1;
                fetch_req_o = 1'b0;
            end
            3'b010: begin
                for (int i = 0; i < (2*ENTRY-2); i++) begin
                    valid_d[i] = valid_q[i+2];
                end
                valid_d[4] = 1'b1;
                valid_d[5] = 1'b1;
                for (int j = 0; j < (ENTRY-1); j++) begin
                    fifo_entry_d[j] = fifo_entry_q[j+1];
                    fifo_pc_d[j] = fifo_pc_q[j+1];
                end
                fifo_entry_d[2] = in_instr_i;
                fifo_pc_d[2] = in_pc_i;

                pop_req_d = 1'b0;
                fetch_req_o = 1'b1;
            end
            3'b011: begin
                for (int i = 0; i < (2*ENTRY-2); i++) begin
                    valid_d[i] = valid_q[i+2];
                end
                valid_d[4] = 1'b1;
                valid_d[5] = 1'b1;
                for (int j = 0; j < (ENTRY-1); j++) begin
                    fifo_entry_d[j] = fifo_entry_q[j+1];
                    fifo_pc_d[j] = fifo_pc_q[j+1];
                end
                fifo_entry_d[2] = in_instr_i;
                fifo_pc_d[2] = in_pc_i;

                pop_req_d = 1'b1;
                fetch_req_o = 1'b1;
            end
            3'b100: begin
                for (int i = 0; i < (2*ENTRY); i++) begin
                    valid_d[i] = '0;
                end
                for (int j = 0; j < (ENTRY); j++) begin
                    fifo_entry_d[j] = '0;
                    fifo_pc_d[j] = '0;
                end
                pop_req_d = 1'b0;
                fetch_req_o = 1'b0;
            end
            3'b101: begin
                for (int i = 0; i < (2*ENTRY); i++) begin
                    valid_d[i] = '0;
                end
                for (int j = 0; j < (ENTRY); j++) begin
                    fifo_entry_d[j] = '0;
                    fifo_pc_d[j] = '0;
                end
                pop_req_d = 1'b0;
                fetch_req_o = 1'b0;
            end
            3'b110: begin
                for (int i = 0; i < (2*ENTRY-2); i++) begin
                    valid_d[i] = '0;
                end
                valid_d[4] = 1'b1;
                valid_d[5] = 1'b1;
                for (int j = 0; j < (ENTRY-1); j++) begin
                    fifo_entry_d[j] = '0;
                    fifo_pc_d[j] = '0;
                end
                fifo_entry_d[2] = in_instr_i;
                fifo_pc_d[2] = in_pc_i;
                pop_req_d = 1'b0;
                fetch_req_o = 1'b1;
            end
            3'b111: begin
                for (int i = 0; i < (2*ENTRY-2); i++) begin
                    valid_d[i] = '0;
                end
                valid_d[4] = 1'b1;
                valid_d[5] = 1'b1;
                for (int j = 0; j < (ENTRY-1); j++) begin
                    fifo_entry_d[j] = '0;
                    fifo_pc_d[j] = '0;
                end
                fifo_entry_d[2] = in_instr_i;
                fifo_pc_d[2] = in_pc_i;
                pop_req_d = 1'b0;
                fetch_req_o = 1'b1;
            end
        endcase
    end

    // check compression
    logic [31:0]        fifo_entry_0;
    assign fifo_entry_0 = fifo_entry_q[0];
    logic [31:0]        fifo_entry_1;
    assign fifo_entry_1 = fifo_entry_q[1];
    


    // read the instruction [1:0] 
    always_comb begin
        if (valid_q[0]) begin
            check_compressed = fifo_entry_0[1:0];
        end else begin
            check_compressed = fifo_entry_0[17:16];
        end
    end

    always_comb begin
        instr_compressed = '0;
        case (check_compressed) 
            2'b00:  instr_compressed = 1'b1;
            2'b01:  instr_compressed = 1'b1;
            2'b10:  instr_compressed = 1'b1;
            2'b11:  instr_compressed = 1'b0;
            default: instr_compressed = 1'b0;
        endcase
    end

    logic [1:0]     out_instr_control;
    assign out_instr_control = {valid_q[0], instr_compressed};

    always_comb begin
        out_pc = RESET_PC;
        if (pop_req_d) begin
            case (out_instr_control) 
                2'b00: begin
                    out_instr = {fifo_entry_1[15:0], fifo_entry_0[31:16]};   // pc[0] + 2
                    out_pc = fifo_pc_q[0] + 32'b10;
                end
                2'b01: begin
                    out_instr = {16'b0, fifo_entry_0[31:16]};                // pc[0] + 2
                    out_pc = fifo_pc_q[0] + 32'b10;
                end
                2'b10: begin
                    out_instr = fifo_entry_0;                                // pc[0]
                    out_pc = fifo_pc_q[0];
                end
                2'b11: begin
                    out_instr = {16'b0, fifo_entry_0[15:0]};                 // pc[0]
                    out_pc = fifo_pc_q[0];
                end
            endcase
        end else begin
            out_instr = '0;
        end
    end

    assign out_instr_o = out_instr;
    assign out_pc_curr_o = out_pc;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < (2*ENTRY); i++) begin
                valid_q[i] <= '0;
            end
            for (int j = 0; j < ENTRY; j++) begin
                fifo_entry_q[j] <= '0;
                fifo_pc_q[j] <= '0;
            end
            pop_req_q <= '0;
        end else begin
            for (int i = 0; i < (2*ENTRY); i++) begin
                valid_q[i] <= valid_d[i];
            end
            for (int j = 0; j < ENTRY; j++) begin
                fifo_entry_q[j] <= fifo_entry_d[j];
                fifo_pc_q[j] <= fifo_pc_d[j];
            end
            pop_req_q <= pop_req_d;
        end
    end

endmodule
