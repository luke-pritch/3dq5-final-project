

# add waves to waveform
add wave Clock_50
add wave -decimal -unsigned uut/SRAM_address
add wave -divider {some label for my divider}
add wave uut/SRAM_we_n
add wave -decimal uut/SRAM_write_data
add wave -decimal uut/SRAM_read_data

add wave uut/M1_START
add wave uut/M1_END
add wave uut/state
add wave uut/M1_unit/state_m1
add wave uut/M1_unit/Multi_Result
add wave -divider {some label for my divider}
add wave uut/M1_unit/RBufferEven
add wave uut/M1_unit/GBufferEven
add wave uut/M1_unit/BBufferEven
add wave -divider {some label for my divider}
add wave uut/M1_unit/RBufferOdd
add wave uut/M1_unit/GBufferOdd
add wave uut/M1_unit/BBufferOdd
add wave -divider {some label for my divider}
add wave uut/M1_unit/UPrimeOdd
add wave uut/M1_unit/VPrimeOdd
add wave uut/M1_unit/Yx76284Even
add wave uut/M1_unit/Yx76284Odd
add wave -divider {some label for my divider}
add wave uut/M1_unit/YBufferEven
add wave uut/M1_unit/YBufferOdd
add wave -decimal uut/M1_unit/VReg
add wave -decimal uut/M1_unit/UReg
add wave -decimal uut/M1_unit/U_address
add wave -decimal uut/M1_unit/V_address
add wave -decimal uut/M1_unit/Y_address
add wave -decimal uut/M1_unit/CommonCounter
add wave -decimal uut/M1_unit/RowCounter
add wave -decimal uut/M1_unit/VPrimeOddFinal
add wave -decimal uut/M1_unit/WriteCounter