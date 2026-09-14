module apb_timer_queue #(
    parameter  int unsigned Depth    = 8,
    parameter  int unsigned NrIrqs   = 32,
    localparam int unsigned IrqWidth = $clog2(NrIrqs)
) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    output logic     [NrIrqs-1:0] irq_pl_o,
    output logic                  irq_full_o,
    output logic                  irq_nfull_o,
    input  logic     [      63:0] mtime_i,
           APB.Slave              apb_sbr
);

  assign apb_sbr.prdata  = 32'b0;
  assign apb_sbr.pslverr = 1'b0;
  assign apb_sbr.pready  = apb_sbr.psel & apb_sbr.penable;

endmodule : apb_timer_queue
