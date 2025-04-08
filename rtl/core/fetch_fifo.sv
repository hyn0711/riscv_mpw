  //              | 31               16 | 15               0 |
  // FIFO entry 0 | Instr 1 [15:0]      | Instr 0 [15:0]     |
  // FIFO entry 1 | Instr 2 [15:0]      | Instr 1 [31:16]    |
  // FIFO entry 2 | Instr 3 [15:0]      | Instr 2 [31:16]    |

module fetch_fifo  #(
    parameter               ENTRY = 3

) (
    input logic                 clk_i,
    input logic                 rst_ni,

    // control signals
    input logic                 clear_i,        // clear the contents of the FIFO

    // input port
    input logic [31:0]          in_instr_i,     // instruction data from IMEM

    input logic                 push_req_i,     // push the instruction to fifo 
    input logic                 pop_req_i,    // pop request from prefetch buffer
    
    // output port
    output logic [31:0]         out_instr_o, 

    output logic                fetch_req_o     // if entry[0] empty, request fetch the instruction
    

);

  // valid = 0 : no valid instruction in the entry[i]
  // valid = 1 : valid instruction in the entry[i] 

  logic             valid_q [2*ENTRY-1:0];
  logic [31:0]      fifo_entry[ENTRY-1:0];

  // logic             out_valid_entry0;

  // assign out_valid_entry0 = valid_q[0];          // valid instruction in entry 0 for pop
  // assign out_instr_o = fifo_entry[0];



  // find the lowest free entry
  logic             lowest_free_entry [ENTRY-1:0];

  assign lowest_free_entry[0] = ~valid_q[0] & ~valid_q[1];
  assign lowest_free_entry[1] = ~valid_q[2] & ~valid_q[3] & valid_q[0] & valid_q[1];
  assign lowest_free_entry[2] = ~valid_q[4] & ~valid_q[5] & valid_q[2] & valid_q[3];


  logic valid_entry [ENTRY-1:0];
  assign valid_entry[0] = valid_q[0] | valid_q[1]; 
  assign valid_entry[1] = valid_q[2] | valid_q[3]; 
  assign valid_entry[2] = valid_q[4] | valid_q[5]; 

  assign fetch_req_o = ~valid_entry[0] | ~valid_entry[1] | ~valid_entry[2];

  // 16b? 32b?
  // instr_compressed = 1 : 16b instruction
  // instr_compressed = 0 : 32b instruction 


  logic instr_compressed;
  logic second_instr_compressed;
  logic instr_uncompressed;

  // pop control signal
  logic entry0_16_16out;
  logic entry0_16out_16;
  logic entry0_32out_16;
  logic entry0_32out;
  
  always_comb begin
    case (fifo_entry[0][1:0]) 
        2'b00:  instr_compressed = 1'b1;
        2'b01:  instr_compressed = 1'b1;
        2'b10:  instr_compressed = 1'b1;
        2'b11:  instr_compressed = 1'b0;
        default: instr_compressed = 1'b0;
    endcase

    if (instr_compressed) begin
        if (fifo_entry[0][17:16] == 2'b11) begin        // 32b[15:0] | 16b
            second_instr_compressed = 1'b0;
            instr_uncompressed = 1'b0;
        end else begin
            second_instr_compressed = 1'b1;
            instr_uncompressed = 1'b0;
        end
    end else begin
        instr_uncompressed = 1'b1;
    end
  end
  

  // reset the valid and fifo entry
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        for (int i = 0; i < (2*ENTRY); i++) begin
            valid_q[i] <= '0;
        end
        for (int j = 0; j < ENTRY; j++) begin
            fifo_entry[j] <= '0;
        end
    end else if (clear_i) begin
        for (int i = 0; i < (2*ENTRY); i++) begin
            valid_q[i] <= '0;
        end
        for (int j = 0; j < ENTRY; j++) begin
            fifo_entry[j] <= '0;
        end
    end
  end

  // push the instruction into the fifo entry
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (push_req_i) begin
        if (lowest_free_entry[0]) begin
            fifo_entry[0] <= in_instr_i;
            valid_q[0] <= 1'b1;     
            valid_q[1] <= 1'b1;
        end else if (lowest_free_entry[1]) begin
            fifo_entry[1] <= in_instr_i;
            valid_q[2] <= 1'b1;
            valid_q[3] <= 1'b1;
        end else if (lowest_free_entry[2]) begin
            fifo_entry[2] <= in_instr_i;
            valid_q[4] <= 1'b1;
            valid_q[5] <= 1'b1;
        end
    end
  end


  // pop control signal
  assign entry0_16_16out = pop_req_i & valid_q[0] & instr_compressed & second_instr_compressed;
  assign entry0_16out_16 = pop_req_i & ~valid_q[0] & second_instr_compressed;
  assign entry0_32out_16 = pop_req_i & ~valid_q[0] & valid_q[2] & ~second_instr_compressed;
  assign entry0_32out = pop_req_i & valid_q[0] & valid_q[1] & instr_uncompressed;


  // pop_valid
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (entry0_16out_16 || entry0_32out) begin
        for (int i = 0; i < (2*ENTRY); i++) begin
            if (i < 4) begin
                valid_q[i] <= valid_q[i+2];
            end else begin
                valid_q[i] <= '0;
            end
        end
    end else if (entry0_16_16out) begin
        for (int i = 0; i < (2*ENTRY); i++) begin
            if (i == 0) begin
                valid_q[i] <= '0;
            end else begin
                valid_q[i] <= valid_q[i];
            end
        end
    end else if (entry0_32out_16) begin
        for (int i = 0; i < (2*ENTRY); i++) begin
            if (i < 4) begin
                if (i ==0) begin
                    valid_q[i] <= '0;
                end else begin
                    valid_q[i] <= valid_q[i+2];
                end
            end else begin
                valid_q[i] <= '0;
            end
        end
    end
  end       
 
  // pop output
  assign out_instr_o = entry0_16_16out ? {16'b0, fifo_entry[0][15:0]}                : 
                       entry0_16out_16 ? {16'b0, fifo_entry[0][31:16]}               : 
                       entry0_32out_16 ? {fifo_entry[1][15:0], fifo_entry[0][31:16]} : 
                       entry0_32out    ? fifo_entry[0]                               : 32'b0;


endmodule

