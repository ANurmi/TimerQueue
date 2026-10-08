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

  localparam int unsigned TsWidth = 64;

  localparam logic [7:0] StatusAddr = 8'h00;
  localparam logic [7:0] ControlAddr = 8'h04;
  //localparam logic [7:0] HandleAddr = 8'h08;
  localparam logic [7:0] RelTsAddr = 8'h0C;
  localparam logic [7:0] AbsTsLoAddr = 8'h10;
  localparam logic [7:0] AbsTsHiAddr = 8'h14;

  logic full, empty;

  logic [31:0] rel_ts_q, rel_ts_d;
  logic [63:0] abs_ts_q, abs_ts_d;

  logic [63:0] push_ts;
  logic [63:0] peek_ts;

  logic [IrqWidth-1:0] pop_payload, push_payload;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      rel_ts_q <= 32'h0;
      abs_ts_q <= 64'h0;
    end else begin
      rel_ts_q <= rel_ts_d;
      abs_ts_q <= abs_ts_d;
    end
  end

  logic apb_event;

  logic push, pop, drop;

  assign apb_event = apb_sbr.penable & apb_sbr.psel;

  assign apb_sbr.pslverr = 1'b0;
  assign apb_sbr.pready = apb_sbr.psel & apb_sbr.penable;

  assign pop = (peek_ts <= mtime_i) & ~empty;

  // TODO: implement
  assign irq_full_o = 1'b0;
  assign irq_nfull_o = 1'b0;


  always_comb begin : irq_dispatch
    irq_pl_o = NrIrqs'('0);
    for (int i = 0; i < NrIrqs; i++) begin
      if ((IrqWidth'(i) == pop_payload) & pop) irq_pl_o[i] = 1'b1;
    end
  end

  always_comb begin : apb_access

    apb_sbr.prdata = 32'h0;
    rel_ts_d       = rel_ts_q;
    abs_ts_d       = abs_ts_q;
    push_ts        = 64'h0;

    push           = 1'b0;
    drop           = 1'b0;
    push_payload   = IrqWidth'(0);

    unique case (apb_sbr.paddr[7:0])
      StatusAddr:  // RO
      if (apb_event & ~apb_sbr.pwrite) begin
      end

      ControlAddr:  // WO
      if (apb_event & apb_sbr.pwrite) begin
        if (apb_sbr.pwdata[0]) begin
          push         = 1'b1;
          push_ts      = mtime_i + 64'(rel_ts_q);
          push_payload = IrqWidth'(apb_sbr.pwdata[31:24]);
        end else if (apb_sbr.pwdata[1]) begin
          push    = 1'b1;
          push_ts = abs_ts_q;
          push_payload = IrqWidth'(apb_sbr.pwdata[31:24]);
        end else if (apb_sbr.pwdata[2]) begin
          //drop = 1'b1;
        end
      end
      /*
      HandleAddr:  // RO
      if (apb_event & ~apb_sbr.pwrite) begin
      end
     */
      RelTsAddr:  // RW
      if (apb_event) begin
        if (apb_sbr.pwrite) begin
          rel_ts_d = apb_sbr.pwdata;
        end else begin
          apb_sbr.prdata = rel_ts_q;
        end
      end

      AbsTsLoAddr:  // RW
      if (apb_event) begin
        if (apb_sbr.pwrite) begin
          abs_ts_d[31:0] = apb_sbr.pwdata;
        end else begin
          apb_sbr.prdata = abs_ts_q[31:0];
        end
      end
      AbsTsHiAddr:  // RW
      if (apb_event) begin
        if (apb_sbr.pwrite) begin
          abs_ts_d[63:32] = apb_sbr.pwdata;
        end else begin
          apb_sbr.prdata = abs_ts_q[63:32];
        end
      end

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
      .push_i          (push),
      .push_payload_i  (push_payload),
      .push_timestamp_i(push_ts),
      .drop_i          (drop),
      .drop_ptr_i      (),
      .drop_payload_o  (),
      .drop_timestamp_o(),
      .pop_i           (pop),
      .empty_o         (empty),
      .full_o          (full),
      .top_ptr_o       (),
      .btm_ptr_o       (),
      .free_ptr_o      (),
      .peek_timestamp_o(peek_ts),
      .payload_o       (pop_payload)
  );

endmodule : apb_timer_queue
