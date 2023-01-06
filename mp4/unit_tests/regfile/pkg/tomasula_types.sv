package tomasula_types;

typedef enum bit[2:0] {
    BRANCH = 3'b000,
    ARITH = 3'b001, 
    AUIPC = 3'b010, 
    JAL = 3'b011, 
    JALR = 3'b100
} op_t;

/* remember to take out rob id's later since they are unnecessary */
typedef struct {
    op_t op;  // 3 bits
    logic [7:0] src1_reg;
    logic src1_valid;
    logic [7:0] src2_reg;
    logic src2_valid;
    logic [2:0] funct3; 
    logic funct7;
    logic [7:0] rd;
    logic [31:0] imm;
} ctl_word; // totals 199 bits

typedef struct {
    op_t op;
    logic [2:0] funct3;
    logic funct7; 
    logic [2:0] src1_tag; 
    logic [31:0] src1_data;
    logic src1_valid;
    logic [2:0] src2_tag;
    logic [31:0] src2_data;
    logic src2_valid;
    logic [2:0] rd_tag;
    logic [31:0] imm;
} res_word; // totals 82 bits

typedef struct packed {
    logic [2:0] tag;
    logic [31:0] data;
} cdb_data; // totals 35 bits

typedef struct packed {
    op_t op;
    logic [2:0] funct3;
    logic funct7; 
    logic [31:0] src1_data;
    logic [31:0] src2_data;
    logic [31:0] imm;
    logic [2:0] tag;
} alu_word;


endpackage : tomasula_types;