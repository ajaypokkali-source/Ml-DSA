`ifndef CONSTANTS_V
`define CONSTANTS_V

//====================================================
// ML-DSA-87 Parameters (FIPS 204)
//====================================================

// Polynomial degree
`define N 256

// Prime modulus
`define Q 8380417

// Primitive root
`define ZETA 1753

// Number of dropped bits
`define D 13

// Number of non-zero coefficients in challenge
`define TAU 60

// Security level
`define LAMBDA 256

// Matrix dimensions
`define K 8
`define L 7

// Secret coefficient bound
`define ETA 2

// Signing parameters
`define GAMMA1 524288
`define GAMMA2 261888

// Beta
`define BETA 120

// Maximum hints
`define OMEGA 75

// Seed lengths
`define SEEDBYTES 32
`define CRHBYTES 64

`endif