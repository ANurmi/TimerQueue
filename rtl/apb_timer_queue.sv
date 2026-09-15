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

  localparam int unsigned TsWidth = 32;

  localparam logic [11:0] StatusAddr = 12'h000;
  localparam logic [11:0] HandleAddr = 12'h004;
  localparam logic [11:0] ControlAddr = 12'h008;
  localparam logic [11:0] RelTsAddr = 12'h00C;
  localparam logic [11:0] AbsTsLoAddr = 12'h010;
  localparam logic [11:0] AbsTsHiAddr = 12'h014;

  logic apb_event;

  assign apb_event = apb_sbr.penable & apb_sbr.psel;

  assign apb_sbr.pslverr = 1'b0;
  assign apb_sbr.pready = apb_sbr.psel & apb_sbr.penable;

  always_comb begin : apb_access
    apb_sbr.prdata = 32'h0;
    unique case (apb_sbr.paddr[11:0])
      default: ;
    endcase
  end : apb_access

  priority_queue #(
      .Depth       (Depth),
      .TimeWidth   (TsWidth),
      .PayloadWidth(IrqWidth)
  ) i_pq (
      .clk_i,
      .rst_ni,
      .push_i          (),
      .push_payload_i  (),
      .push_timestamp_i(),
      .drop_i          (),
      .drop_ptr_i      (),
      .drop_payload_o  (),
      .drop_timestamp_o(),
      .pop_i           (),
      .empty_o         (),
      .full_o          (),
      .top_ptr_o       (),
      .btm_ptr_o       (),
      .free_ptr_o      (),
      .peek_data_o     (),
      .payload_o       ()
  );

endmodule : apb_timer_queue
