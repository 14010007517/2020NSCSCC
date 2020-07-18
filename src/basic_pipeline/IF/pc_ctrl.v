module pc_ctrl(
    input wire branchD,
    input wire branchM,
    input wire succM,
    input wire actual_takeM,
    input wire pred_takeD,

    output wire [1:0] pc_sel
);
 
    
    assign pc_sel = (branchM & ~succM & actual_takeM) ? 2'b10:
                    (branchM & ~succM & ~actual_takeM) ? 2'b11:
                    (branchD & ~branchM & pred_takeD ||
                     branchD & branchM & succM & pred_takeD) ? 2'b01:
                     2'b00;
endmodule