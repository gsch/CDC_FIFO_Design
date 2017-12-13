// Multi-Cycle Path (MCP ) formulation toggle-pulse generation with ready-ack
module multibit_mcp_sync #(
  parameter DATA_WIDTH = 32
) (
  input  logic                  aclk,
  input  logic                  areset,
  input  logic                  avalid,
  input  logic [DATA_WIDTH-1:0] adata,
  output logic                  aready,
  input  logic                  bclk,
  input  logic                  breset,
  output logic                  bvalid,
  output logic [DATA_WIDTH-1:0] bdata,
  input  logic                  bready
);
  
  logic [DATA_WIDTH-1:0] data;
  // Transmit data sample register
  always_ff @(posedge aclk) begin
    if (avalid && aready) begin
      data <= adata;
    end
  end
  // generate aenable-using toggle-FF
  logic aenable,benable;
  always_ff @(posedge aclk) begin
    if (areset) begin
      aenable <= 1'b0;
    end else begin
      aenable <= aenable ^ (avalid & aready);
    end
  end
  // Receive data sample register
  always_ff @(posedge bclk) begin
    if (bvalid && bready) begin
      bdata <= data;
    end
  end
  // generate back-using toggle-FF
  logic aack,back;
  always_ff @(posedge bclk) begin
    if (breset) begin
      back <= 1'b0;
    end else begin
      back <= back ^ (bvalid & bready);
    end
  end
  // Sync back to aclk
  multibit_mcp_double_sync_pulsegen
  multibit_mcp_double_sync_pulsegen_aack (
    .clk(aclk),
    .reset(areset),
    .d(back),
    .p(aack)
  );
  // Sync aenable to benable
  multibit_mcp_double_sync_pulsegen
  multibit_mcp_double_sync_pulsegen_benable (
    .clk(bclk),
    .reset(breset),
    .d(aenable),
    .p(benable)
  );
  
endmodule

module multibit_mcp_double_sync_pulsegen (
  input  logic clk,
  input  logic reset,
  input  logic d,
  output logic p
);
  
  logic q0,q;
  logic q_r;
  // Double Sync-Single-bit-CDC
  always_ff @(posedge clk) begin
    if (reset) begin
      {q,q0} <= '0;
    end else begin
      {q,q0} <= {q0,d};
    end
  end
  // Pulse generator
  always_ff @(posedge clk) begin
    if (reset) begin
      q_r <= '0;
    end else begin
      q_r <= q;
    end
  end
  assign p = q^q_r;
  
endmodule