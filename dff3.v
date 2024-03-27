`timescale 1ns / 1ps

module programcounter(nextPc, clk, pc);
    input [31:0] nextPc;
    input clk;
    output reg[31:0] pc;
    initial
        begin
            pc <= 32'b01100100;
        end
    always @ (posedge clk)
        begin
            pc <= nextPc;
        end
endmodule

module instructionmemory(input [31:0] pc, output reg [31:0] instOut);
    reg [31:0] memory [0:63];
    
    initial 
        begin
            memory[25] = {6'b000000, 5'b00001, 5'b00010, 5'b00011, 5'b00000, 6'b100000};
            memory[26] = {6'b000000, 5'b01001, 5'b00011, 5'b00100, 5'b00000, 6'b100010};
            memory[27] = {6'b000000, 5'b00011, 5'b01001, 5'b00101, 5'b00000, 6'b100101};
            memory[28] = {6'b000000, 5'b00011, 5'b01001, 5'b00110, 5'b00000, 6'b100110};
            memory[29] = {6'b000000, 5'b00011, 5'b01001, 5'b00111, 5'b00000, 6'b100100};
        end
    always @ (*)
        begin
            instOut <= memory[pc[7:2]];
        end
endmodule

module pcadder(input [31:0] pc, output reg [31:0] nextPc);
    always @ (*)
        begin
            nextPc <= pc + 4;
        end
endmodule

module ifidpipelineregister(input [31:0] instOut, input clk, output reg [31:0] dinstOut);
    always @ (posedge clk)
        begin
            dinstOut <= instOut;
        end
endmodule

module controlunit(input [5:0] op, input [5:0] func, input [4:0] rs, input [4:0] rt, input [4:0] mdestReg, input mm2reg, input mwreg, input [4:0] edestReg, input em2reg, input ewreg, output reg wreg, output reg m2reg, output reg wmem, output reg [3:0] aluc, output reg aluimm, output reg regrt, output reg [1:0] fwdb, output reg [1:0] fwda);
    always @ (*)
        begin
        case(op)
            6'b000000:
                begin
                    wreg <= 1'b1;
                    m2reg <= 1'b0;
                    wmem <= 1'b0;
                    aluimm <= 1'b0;
                    regrt <= 1'b0;
                    
                    case(func)
                        6'b100000:
                            begin
                                aluc <= 4'b0010;
                            end
                        6'b100010:
                            begin
                                aluc <= 4'b0110;
                            end
                        6'b100100:
                            begin
                                aluc <= 4'b0000;
                            end
                        6'b100101:
                            begin
                                aluc <= 4'b0001;
                            end
                        6'b100110:
                            begin
                                aluc <= 4'b0011;
                            end
                    endcase
                end
            6'b100011:
                begin
                    wreg <= 1'b1;
                    m2reg <= 1'b1;
                    wmem <= 1'b0;
                    aluc <= 4'b0010;
                    aluimm <= 1'b1;
                    regrt <= 1'b1;
                end
            6'b101011:
                begin
                    wreg <= 1'b0;
                    m2reg <= 1'b0;
                    wmem <= 1'b1;
                    aluc <= 4'b0010;
                    aluimm <= 1'b1;
                    regrt <= 1'b0;
                end
            endcase
        end
    always @ (*)
        begin
        if (ewreg && (edestReg == rs) && !em2reg) 
            begin
                fwda = 2'b01;
            end
        else if (mwreg && (mdestReg == rs) && !mm2reg)
            begin
                fwda = 2'b10;
            end
        else if (mwreg && (mdestReg == rs) && mm2reg)
            begin
                fwda = 2'b11;
            end
        else 
            begin
                fwda = 2'b00;
            end
        
        if (ewreg && (edestReg == rt) && !em2reg) 
            begin
                fwdb = 2'b01;
            end
        else if (mwreg && (mdestReg == rt) && !mm2reg)
            begin
                fwdb = 2'b10;
            end
        else if (mwreg && (mdestReg == rt) && mm2reg)
            begin
                fwdb = 2'b11;
            end
        else 
            begin
                fwdb = 2'b00;
            end
        end
    initial
        begin
            fwda <= 2'b00;
            fwdb <= 2'b00;
        end
endmodule

module regrtmultiplexer(input [4:0] rt, input [4:0] rd, input regrt, output reg [4:0] destReg);
    always @ (*)
        begin
            if (regrt == 0) 
                begin
                    destReg <= rd;
                end
            else if (regrt == 1) 
                begin
                    destReg <= rt;
                end
        end
endmodule

module registerfile(input [4:0] rs, input [4:0] rt, input [4:0] wdestReg, input [31:0] wbData, input wwreg, input clk, output reg [31:0] qa1, output reg [31:0] qb1);
    reg [31:0] registers [31:0];
    integer i;
    initial 
        begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] = 32'h00000000;
            end
            registers[1] = 32'hA00000AA;
            registers[2] = 32'h10000011;
            registers[3] = 32'h20000022;
            registers[4] = 32'h30000033;
            registers[5] = 32'h40000044;
            registers[6] = 32'h50000055;
            registers[7] = 32'h60000066;
            registers[8] = 32'h70000077;
            registers[9] = 32'h80000088;
            registers[10] = 32'h90000099;
        end
    always @ (*)
        begin
            qa1 <= registers[rs];
            qb1 <= registers[rt];
        end
    always @ (negedge clk)
        begin
            if (wwreg == 1)
                begin
                    registers[wdestReg] <= wbData;
                end
        end
endmodule

module immediateextender(input [15:0] imm, output reg [31:0] imm32);
    always @ (*)
        begin
            imm32[15:0] <= imm;
            if (imm[15] == 1) 
                begin
                    imm32[31:16] <= 16'hFFFF;
                end
            else 
                begin
                    imm32[31:16] <= 16'h0000;
                end
        end
endmodule

module idexepipelineregister(input wreg, input m2reg, input wmem, input [3:0] aluc, input aluimm, input [5:0] destReg, input [31:0] qa, input [31:0] qb, input [31:0] imm32, input clk, output reg ewreg, output reg em2reg, output reg ewmem, output reg [3:0] ealuc, output reg ealuimm, output reg [4:0] edestReg, output reg [31:0] eqa, output reg [31:0] eqb, output reg [31:0] eimm32);
    always @ (posedge clk)
        begin
            ewreg <= wreg;
            em2reg <= m2reg;
            ewmem <= wmem;
            ealuc <= aluc;
            ealuimm <= aluimm;
            edestReg <= destReg;
            eqa <= qa;
            eqb <= qb;
            eimm32 <= imm32;
        end
endmodule

module datapath(input clk, output wire [31:0] pc, output wire [31:0] dinstOut, output wire ewreg, output wire em2reg, 
output wire ewmem, output wire [3:0] ealuc, output wire ealuimm, output wire [4:0] edestReg, output wire [31:0] eqa, 
output wire [31:0] eqb, output wire [31:0] eimm32, output wire mwreg, output wire mm2reg, output wire mwmem, 
output wire [4:0] mdestReg, output wire [31:0] mr, output wire [31:0] mqb, output wire wwreg, output wire wm2reg, 
output wire [4:0] wdestReg, output wire [31:0] wr, output wire [31:0] wdo, output wire [31:0] qa, output wire [31:0] qb);
    wire [31:0] nextPc;
    wire [31:0] instOut;
    wire wreg;
    wire m2reg;
    wire wmem;
    wire [3:0] aluc;
    wire aluimm;
    wire regrt;
    wire [4:0] destReg;
    wire [31:0] qa1;
    wire [31:0] qb1;
    wire [31:0] imm32;
    wire [5:0] op;
    wire [5:0] func;
    wire [4:0] rs;
    wire [4:0] rt;
    wire [4:0] rd;
    wire [15:0] imm;
    wire [31:0] b;
    wire [31:0] r;
    wire [31:0] mdo;
    wire [31:0] wbData;
    wire [1:0] fwda;
    wire [1:0] fwdb;
    
    assign op = dinstOut[31:26];
    assign rs = dinstOut[25:21];
    assign rt = dinstOut[20:16];
    assign rd = dinstOut[15:11];
    assign func = dinstOut[5:0];
    assign imm = dinstOut[15:0];
    
    programcounter counter(.nextPc(nextPc), .clk(clk), .pc(pc));
    instructionmemory memory(.pc(pc), .instOut(instOut));
    pcadder adder(.pc(pc), .nextPc(nextPc));
    ifidpipelineregister ifidpipe(.instOut(instOut), .clk(clk), .dinstOut(dinstOut));
    controlunit control(.op(op), .func(func), .rs(rs), .rt(rt), .mdestReg(mdestReg), .mm2reg(mm2reg), .mwreg(mwreg), .edestReg(edestReg), .em2reg(em2reg), .ewreg(ewreg), .wreg(wreg), .m2reg(m2reg), .wmem(wmem), .aluc(aluc), .aluimm(aluimm), .regrt(regrt), .fwdb(fwdb), .fwda(fwda));
    regrtmultiplexer regrtmult(.rt(rt), .rd(rd), .regrt(regrt), .destReg(destReg));
    registerfile regfile(.rs(rs), .rt(rt), .wdestReg(wdestReg), .wbData(wbData), .wwreg(wwreg), .clk(clk), .qa1(qa1), .qb1(qb1));
    immediateextender immextender(.imm(imm), .imm32(imm32));
    idexepipelineregister idexepipe(.wreg(wreg), .m2reg(m2reg), .wmem(wmem), .aluc(aluc), .aluimm(aluimm), .destReg(destReg), .qa(qa), .qb(qb), .imm32(imm32), .clk(clk), .ewreg(ewreg), .em2reg(em2reg), .ewmem(ewmem), .ealuc(ealuc), .ealuimm(ealuimm), .edestReg(edestReg), .eqa(eqa), .eqb(eqb), .eimm32(eimm32));
    alumux alumux(.eqb(eqb), .eimm32(eimm32), .ealuimm(ealuimm), .b(b));
    alu alu(.eqa(eqa), .b(b), .ealuc(ealuc), .r(r));
    exemempipelineregister exemempipe(.ewreg(ewreg), .em2reg(em2reg), .ewmem(ewmem), .edestReg(edestReg), .r(r), .eqb(eqb), .clk(clk), .mwreg(mwreg), .mm2reg(mm2reg), .mwmem(mwmem), .mdestReg(mdestReg), .mr(mr), .mqb(mqb));
    datamemory datamemory(.mr(mr), .mqb(mqb), .mwmem(mwmem), .clk(clk), .mdo(mdo));
    memwbpipelineregister memwbpipe(.mwreg(mwreg), .mm2reg(mm2reg), .mdestReg(mdestReg), .mr(mr), .mdo(mdo), .clk(clk), .wwreg(wwreg), .wm2reg(wm2reg), .wdestReg(wdestReg), .wr(wr), .wdo(wdo));
    wbmux wbmux(.wr(wr), .wdo(wdo), .wm2reg(wm2reg), .wbData(wbData));
    fwdamux fwdamux(.fwda(fwda), .qa1(qa1), .r(r), .mr(mr), .mdo(mdo), .qa(qa));
    fwdbmux fwdbmux(.fwdb(fwdb), .qb1(qb1), .r(r), .mr(mr), .mdo(mdo), .qb(qb));
endmodule

module alumux(input [31:0] eqb, input [31:0] eimm32, input ealuimm, output reg [31:0] b);
    always @ (*)
        begin 
            if (ealuimm == 0)
                begin
                    b <= eqb;
                end
            else 
                begin
                    b <= eimm32;
                end
        end
endmodule

module alu(input [31:0] eqa, input [31:0] b, input [3:0] ealuc, output reg [31:0] r);
    always @ (*)
        begin
            if (ealuc == 4'b0000)
                begin
                    r <= eqa & b;
                end
            else if (ealuc == 4'b0001)
                begin
                    r <= eqa | b;
                end
            else if (ealuc == 4'b0010)
                begin
                    r <= eqa + b;
                end
            else if (ealuc == 4'b0110)
                begin
                    r <= eqa - b;
                end
            else if (ealuc == 4'b0011)
                begin
                    r <= eqa ^ b;
                end
        end
endmodule

module exemempipelineregister(input ewreg, input em2reg, input ewmem, input [4:0] edestReg, input [31:0] r, input [31:0] eqb, input clk, output reg mwreg, output reg mm2reg, output reg mwmem, output reg [4:0] mdestReg, output reg [31:0] mr, output reg [31:0] mqb);    
    always @ (posedge clk)
        begin
            mwreg <= ewreg;
            mm2reg <= em2reg;
            mwmem <= ewmem;
            mdestReg <= edestReg;
            mr <= r;
            mqb <= eqb;
        end
endmodule

module datamemory(input [31:0] mr, input [31:0] mqb, input mwmem, input clk, output reg [31:0] mdo);
    reg [31:0] memory [63:0];
    
    initial 
        begin
            memory[0] = 32'hA00000AA;
            memory[1] = 32'h10000011;
            memory[2] = 32'h20000022;
            memory[3] = 32'h30000033;
            memory[4] = 32'h40000044;
            memory[5] = 32'h50000055;
            memory[6] = 32'h60000066;
            memory[7] = 32'h70000077;
            memory[8] = 32'h80000088;
            memory[9] = 32'h90000099;
        end
    always @ (*)
        begin
            mdo <= memory[mr[7:2]];
        end
    always @ (negedge clk)
        begin
            if (mwmem == 1)
                begin
                    memory[mr[7:2]] <= mqb;
                end
        end
endmodule

module memwbpipelineregister(input mwreg, input mm2reg, input [4:0] mdestReg, input [31:0] mr, input [31:0] mdo, input clk, output reg wwreg, output reg wm2reg, output reg [4:0] wdestReg, output reg [31:0] wr, output reg [31:0] wdo);
    always @ (posedge clk)
        begin
            wwreg <= mwreg;
            wm2reg <= mm2reg;
            wdestReg <= mdestReg;
            wr <= mr;
            wdo <= mdo;
        end    
endmodule

module wbmux(input [31:0] wr, input [31:0] wdo, input wm2reg, output reg [31:0] wbData);
    always @ (*)
        begin
            if (wm2reg == 0)
                begin
                    wbData <= wr;
                end
            else
                begin
                    wbData <= wdo;
                end
        end
endmodule

module fwdamux(input [1:0] fwda, input [31:0] qa1, input [31:0] r, input [31:0] mr, input [31:0] mdo, output reg [31:0] qa);
    always @ (*)
        begin
            if (fwda == 2'b00)
                begin
                    qa <= qa1;
                end
            else if (fwda == 2'b01)
                begin
                    qa <= r;
                end
            else if (fwda == 2'b10)
                begin
                    qa <= mr;
                end
            else if (fwda == 2'b11)
                begin
                    qa <= mdo;
                end
        end
endmodule

module fwdbmux(input [1:0] fwdb, input [31:0] qb1, input [31:0] r, input [31:0] mr, input [31:0] mdo, output reg [31:0] qb);
    always @ (*)
        begin
            if (fwdb == 2'b00)
                begin
                    qb <= qb1;
                end
            else if (fwdb == 2'b01)
                begin
                    qb <= r;
                end
            else if (fwdb == 2'b10)
                begin
                    qb <= mr;
                end
            else if (fwdb == 2'b11)
                begin
                    qb <= mdo;
                end
        end
endmodule