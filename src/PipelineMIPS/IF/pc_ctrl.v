module pc_ctrl(
    input wire branchD,
    input wire branchM,
    input wire succM,
    input wire actual_takeM,
    input wire pred_takeD,

    input wire pc_trapM,
    input wire jumpD,
    input wire jump_conflictD,
    input wire jump_conflictE,

    output reg [2:0] pc_sel
);
    always @(*) begin
        if(pc_trapM)
            pc_sel = 3'b110;
        else if(branchM & ~succM & ~actual_takeM)
            pc_sel = 3'b101;
        else if(branchM & ~succM & actual_takeM)
            pc_sel = 3'b100;
        else if(jump_conflictE)
            pc_sel = 3'b011;
        else if(jumpD & ~jump_conflictD)
            pc_sel = 3'b010;
        else if(branchD & ~branchM & pred_takeD ||
                     branchD & branchM & succM & pred_takeD)
            pc_sel = 3'b001;
        else
            pc_sel = 3'b000;
    end

    // assign pc_sel = (branchM & ~succM & actual_takeM) ? 2'b10:
    //                 (branchM & ~succM & ~actual_takeM) ? 2'b11:
    //                 (branchD & ~branchM & pred_takeD ||
    //                  branchD & branchM & succM & pred_takeD) ? 2'b01:
    //                  2'b00;

    // assign pc_sel2[0] = pc_trapM | jumpD & ~jump_conflictD & ~jump_conflictE;
    // assign pc_sel2[1] = pc_trapM | jump_conflictE;

    // always @(*) begin
    //     if(pc_trapM)
    //         pc_sel2 = 2'b11;
    //     else if(jump_conflictE)
    //         pc_sel2 = 2'b10;
    //     else if(jumpD & ~jump_conflictD)
    //         pc_sel2 = 2'b01;
    //     else
    //         pc_sel2 = 2'b00;
    // end
endmodule