package adaptor_types;
/***************************** Param Declarations ******************************/
// Maximum line size (in bits)
parameter int line_width_p = 256;

// Maximum burst size (in bits)
parameter int burst_width_p = 64;

// Address width (in bits)
parameter int addr_width_p = 32;

// Number of bursts
parameter int num_bursts_p = 4;

typedef logic [line_width_p-1:0] line_t;
typedef logic [burst_width_p-1:0] burst_t;
typedef logic [addr_width_p-1:0] addr_t;

endpackage : adaptor_types;

