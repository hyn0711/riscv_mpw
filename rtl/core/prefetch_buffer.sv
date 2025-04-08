module prefetch_buffer #(
    parameter
) (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [31:0]          in_instr_i,

    // input_ control signal
    input logic                 branch_i,

    // fetch signal
    output logic                instr_fetch_o,      // fetch request signal to IF stage 
    output logic [31:0]         out_instr_o
);


// fifo unit 
logic               clear;          //

logic               push_req;
logic               pop_req;

logic               fetch_req;          //


// clear signal to fifo if branch instruction
assign clear = branch_i;

// fetch instruction signal to IMEM & push fifo or no need to push
assign instr_fetch_o = fetch_req;           // send the fetch request signal to fetch stage 

// push, pop control signal
// stall 생기면 push, pop stop...?



// fifo module 
fetch_fifo #(
    .ENTRY ()
) fifo_if (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),

    .clear_i        (clear),    

    .in_instr_i     (in_instr_i),   

    .push_req_i     (push_req),    
    .pop_req_i      (pop_req),   
    
    .out_instr_o    (out_instr_o), 

    .fetch_req_o    (fetch_req)

);


endmodule