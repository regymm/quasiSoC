RISCV_PATH=/opt/riscv32i/bin
TESTS_PATH=./riscv_tests
all: 
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im  firmware/start.S -o firmware/start.o
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/addi.o -DTEST_FUNC_NAME=addi \
		-DTEST_FUNC_TXT='"addi"' -DTEST_FUNC_RET=addi_ret $(TESTS_PATH)/addi.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/add.o -DTEST_FUNC_NAME=add \
		-DTEST_FUNC_TXT='"add"' -DTEST_FUNC_RET=add_ret $(TESTS_PATH)/add.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/andi.o -DTEST_FUNC_NAME=andi \
		-DTEST_FUNC_TXT='"andi"' -DTEST_FUNC_RET=andi_ret $(TESTS_PATH)/andi.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/and.o -DTEST_FUNC_NAME=and \
		-DTEST_FUNC_TXT='"and"' -DTEST_FUNC_RET=and_ret $(TESTS_PATH)/and.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/auipc.o -DTEST_FUNC_NAME=auipc \
		-DTEST_FUNC_TXT='"auipc"' -DTEST_FUNC_RET=auipc_ret $(TESTS_PATH)/auipc.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/beq.o -DTEST_FUNC_NAME=beq \
		-DTEST_FUNC_TXT='"beq"' -DTEST_FUNC_RET=beq_ret $(TESTS_PATH)/beq.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/bge.o -DTEST_FUNC_NAME=bge \
		-DTEST_FUNC_TXT='"bge"' -DTEST_FUNC_RET=bge_ret $(TESTS_PATH)/bge.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/bgeu.o -DTEST_FUNC_NAME=bgeu \
		-DTEST_FUNC_TXT='"bgeu"' -DTEST_FUNC_RET=bgeu_ret $(TESTS_PATH)/bgeu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/blt.o -DTEST_FUNC_NAME=blt \
		-DTEST_FUNC_TXT='"blt"' -DTEST_FUNC_RET=blt_ret $(TESTS_PATH)/blt.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/bltu.o -DTEST_FUNC_NAME=bltu \
		-DTEST_FUNC_TXT='"bltu"' -DTEST_FUNC_RET=bltu_ret $(TESTS_PATH)/bltu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/bne.o -DTEST_FUNC_NAME=bne \
		-DTEST_FUNC_TXT='"bne"' -DTEST_FUNC_RET=bne_ret $(TESTS_PATH)/bne.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/div.o -DTEST_FUNC_NAME=div \
		-DTEST_FUNC_TXT='"div"' -DTEST_FUNC_RET=div_ret $(TESTS_PATH)/div.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/divu.o -DTEST_FUNC_NAME=divu \
		-DTEST_FUNC_TXT='"divu"' -DTEST_FUNC_RET=divu_ret $(TESTS_PATH)/divu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/jalr.o -DTEST_FUNC_NAME=jalr \
		-DTEST_FUNC_TXT='"jalr"' -DTEST_FUNC_RET=jalr_ret $(TESTS_PATH)/jalr.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/jal.o -DTEST_FUNC_NAME=jal \
		-DTEST_FUNC_TXT='"jal"' -DTEST_FUNC_RET=jal_ret $(TESTS_PATH)/jal.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/j.o -DTEST_FUNC_NAME=j \
		-DTEST_FUNC_TXT='"j"' -DTEST_FUNC_RET=j_ret $(TESTS_PATH)/j.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/lb.o -DTEST_FUNC_NAME=lb \
		-DTEST_FUNC_TXT='"lb"' -DTEST_FUNC_RET=lb_ret $(TESTS_PATH)/lb.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/lbu.o -DTEST_FUNC_NAME=lbu \
		-DTEST_FUNC_TXT='"lbu"' -DTEST_FUNC_RET=lbu_ret $(TESTS_PATH)/lbu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/lh.o -DTEST_FUNC_NAME=lh \
		-DTEST_FUNC_TXT='"lh"' -DTEST_FUNC_RET=lh_ret $(TESTS_PATH)/lh.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/lhu.o -DTEST_FUNC_NAME=lhu \
		-DTEST_FUNC_TXT='"lhu"' -DTEST_FUNC_RET=lhu_ret $(TESTS_PATH)/lhu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/lui.o -DTEST_FUNC_NAME=lui \
		-DTEST_FUNC_TXT='"lui"' -DTEST_FUNC_RET=lui_ret $(TESTS_PATH)/lui.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/lw.o -DTEST_FUNC_NAME=lw \
		-DTEST_FUNC_TXT='"lw"' -DTEST_FUNC_RET=lw_ret $(TESTS_PATH)/lw.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/mulh.o -DTEST_FUNC_NAME=mulh \
		-DTEST_FUNC_TXT='"mulh"' -DTEST_FUNC_RET=mulh_ret $(TESTS_PATH)/mulh.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/mulhsu.o -DTEST_FUNC_NAME=mulhsu \
		-DTEST_FUNC_TXT='"mulhsu"' -DTEST_FUNC_RET=mulhsu_ret $(TESTS_PATH)/mulhsu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/mulhu.o -DTEST_FUNC_NAME=mulhu \
		-DTEST_FUNC_TXT='"mulhu"' -DTEST_FUNC_RET=mulhu_ret $(TESTS_PATH)/mulhu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/mul.o -DTEST_FUNC_NAME=mul \
		-DTEST_FUNC_TXT='"mul"' -DTEST_FUNC_RET=mul_ret $(TESTS_PATH)/mul.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/ori.o -DTEST_FUNC_NAME=ori \
		-DTEST_FUNC_TXT='"ori"' -DTEST_FUNC_RET=ori_ret $(TESTS_PATH)/ori.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/or.o -DTEST_FUNC_NAME=or \
		-DTEST_FUNC_TXT='"or"' -DTEST_FUNC_RET=or_ret $(TESTS_PATH)/or.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/rem.o -DTEST_FUNC_NAME=rem \
		-DTEST_FUNC_TXT='"rem"' -DTEST_FUNC_RET=rem_ret $(TESTS_PATH)/rem.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/remu.o -DTEST_FUNC_NAME=remu \
		-DTEST_FUNC_TXT='"remu"' -DTEST_FUNC_RET=remu_ret $(TESTS_PATH)/remu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/sb.o -DTEST_FUNC_NAME=sb \
		-DTEST_FUNC_TXT='"sb"' -DTEST_FUNC_RET=sb_ret $(TESTS_PATH)/sb.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/sh.o -DTEST_FUNC_NAME=sh \
		-DTEST_FUNC_TXT='"sh"' -DTEST_FUNC_RET=sh_ret $(TESTS_PATH)/sh.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/simple.o -DTEST_FUNC_NAME=simple \
		-DTEST_FUNC_TXT='"simple"' -DTEST_FUNC_RET=simple_ret $(TESTS_PATH)/simple.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/slli.o -DTEST_FUNC_NAME=slli \
		-DTEST_FUNC_TXT='"slli"' -DTEST_FUNC_RET=slli_ret $(TESTS_PATH)/slli.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/sll.o -DTEST_FUNC_NAME=sll \
		-DTEST_FUNC_TXT='"sll"' -DTEST_FUNC_RET=sll_ret $(TESTS_PATH)/sll.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/slti.o -DTEST_FUNC_NAME=slti \
		-DTEST_FUNC_TXT='"slti"' -DTEST_FUNC_RET=slti_ret $(TESTS_PATH)/slti.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/sltiu.o -DTEST_FUNC_NAME=sltiu \
		-DTEST_FUNC_TXT='"sltiu"' -DTEST_FUNC_RET=sltiu_ret $(TESTS_PATH)/sltiu.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/slt.o -DTEST_FUNC_NAME=slt \
		-DTEST_FUNC_TXT='"slt"' -DTEST_FUNC_RET=slt_ret $(TESTS_PATH)/slt.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/srai.o -DTEST_FUNC_NAME=srai \
		-DTEST_FUNC_TXT='"srai"' -DTEST_FUNC_RET=srai_ret $(TESTS_PATH)/srai.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/sra.o -DTEST_FUNC_NAME=sra \
		-DTEST_FUNC_TXT='"sra"' -DTEST_FUNC_RET=sra_ret $(TESTS_PATH)/sra.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/srli.o -DTEST_FUNC_NAME=srli \
		-DTEST_FUNC_TXT='"srli"' -DTEST_FUNC_RET=srli_ret $(TESTS_PATH)/srli.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/srl.o -DTEST_FUNC_NAME=srl \
		-DTEST_FUNC_TXT='"srl"' -DTEST_FUNC_RET=srl_ret $(TESTS_PATH)/srl.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/sub.o -DTEST_FUNC_NAME=sub \
		-DTEST_FUNC_TXT='"sub"' -DTEST_FUNC_RET=sub_ret $(TESTS_PATH)/sub.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/sw.o -DTEST_FUNC_NAME=sw \
		-DTEST_FUNC_TXT='"sw"' -DTEST_FUNC_RET=sw_ret $(TESTS_PATH)/sw.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/xori.o -DTEST_FUNC_NAME=xori \
		-DTEST_FUNC_TXT='"xori"' -DTEST_FUNC_RET=xori_ret $(TESTS_PATH)/xori.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32im -o $(TESTS_PATH)/xor.o -DTEST_FUNC_NAME=xor \
		-DTEST_FUNC_TXT='"xor"' -DTEST_FUNC_RET=xor_ret $(TESTS_PATH)/xor.S
	\
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/csr.o -DTEST_FUNC_NAME=csr \
		-DTEST_FUNC_TXT='"csr"' -DTEST_FUNC_RET=csr_ret $(TESTS_PATH)/csr.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/mcsr.o -DTEST_FUNC_NAME=mcsr \
		-DTEST_FUNC_TXT='"mcsr"' -DTEST_FUNC_RET=mcsr_ret $(TESTS_PATH)/mcsr.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amoadd_w.o -DTEST_FUNC_NAME=amoadd_w \
		-DTEST_FUNC_TXT='"amoadd_w"' -DTEST_FUNC_RET=amoadd_w_ret $(TESTS_PATH)/amoadd_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amoand_w.o -DTEST_FUNC_NAME=amoand_w \
		-DTEST_FUNC_TXT='"amoand_w"' -DTEST_FUNC_RET=amoand_w_ret $(TESTS_PATH)/amoand_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amoor_w.o -DTEST_FUNC_NAME=amoor_w \
		-DTEST_FUNC_TXT='"amoor_w"' -DTEST_FUNC_RET=amoor_w_ret $(TESTS_PATH)/amoor_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amoswap_w.o -DTEST_FUNC_NAME=amoswap_w \
		-DTEST_FUNC_TXT='"amoswap_w"' -DTEST_FUNC_RET=amoswap_w_ret $(TESTS_PATH)/amoswap_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amoxor_w.o -DTEST_FUNC_NAME=amoxor_w \
		-DTEST_FUNC_TXT='"amoxor_w"' -DTEST_FUNC_RET=amoxor_w_ret $(TESTS_PATH)/amoxor_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amomax_w.o -DTEST_FUNC_NAME=amomax_w \
		-DTEST_FUNC_TXT='"amomax_w"' -DTEST_FUNC_RET=amomax_w_ret $(TESTS_PATH)/amomax_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amomaxu_w.o -DTEST_FUNC_NAME=amomaxu_w \
		-DTEST_FUNC_TXT='"amomaxu_w"' -DTEST_FUNC_RET=amomaxu_w_ret $(TESTS_PATH)/amomaxu_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amomin_w.o -DTEST_FUNC_NAME=amomin_w \
		-DTEST_FUNC_TXT='"amomin_w"' -DTEST_FUNC_RET=amomin_w_ret $(TESTS_PATH)/amomin_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/amominu_w.o -DTEST_FUNC_NAME=amominu_w \
		-DTEST_FUNC_TXT='"amominu_w"' -DTEST_FUNC_RET=amominu_w_ret $(TESTS_PATH)/amominu_w.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/lrsc.o -DTEST_FUNC_NAME=lrsc \
		-DTEST_FUNC_TXT='"lrsc_w"' -DTEST_FUNC_RET=lrsc_ret $(TESTS_PATH)/lrsc.S
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -c -march=rv32ima -o $(TESTS_PATH)/scall.o -DTEST_FUNC_NAME=scall \
		-DTEST_FUNC_TXT='"scall"' -DTEST_FUNC_RET=scall_ret $(TESTS_PATH)/scall.S
	\
	$(RISCV_PATH)/riscv32-unknown-elf-gcc -Os -ffreestanding -nostdlib -o firmware/firmware.elf \
		-Wl,-Bstatic,-T,firmware/linker.ld \
		firmware/start.o $(TESTS_PATH)/*.o -lgcc
	$(RISCV_PATH)/riscv32-unknown-elf-objcopy -O binary firmware/firmware.elf firmware/firmware.bin

clean:
	-rm firmware/*.o firmware/*.elf $(TESTS_PATH)/*.o




