`ifndef I3C_TARGET_DRIVER_BFM_INCLUDED_
`define I3C_TARGET_DRIVER_BFM_INCLUDED_
//--------------------------------------------------------------------------------------------
// Class    :i3c_target_driver_bfm
// Description  : Connects with the HVL driver_proxy for driving the stimulus
//--------------------------------------------------------------------------------------------
import i3c_globals_pkg::*;
interface i3c_target_driver_bfm #(parameter string NAME = "I3C_target_DRIVER_BFM")
                               (input pclk, 
                               input areset,
                               input scl_i,
                               output reg scl_o,
                               output reg scl_oen,
                               input sda_i,
                               output reg sda_o,
                               output reg sda_oen);
  
  i3c_fsm_state_e state;
  i3c_transfer_bits_s dataPacketStruck;
  i3c_transfer_cfg_s configPacketStruck;
  bit [7:0] rdata;

  import uvm_pkg::*;
  `include "uvm_macros.svh" 
  
  import i3c_target_pkg::i3c_target_driver_proxy;
  
  i3c_target_driver_proxy i3c_target_drv_proxy_h;
  
  initial begin
    $display(NAME);
  end
  
  task wait_for_system_reset();
    state = RESET_DEACTIVATED;
    @(negedge areset);
    state = RESET_ACTIVATED;
    @(posedge areset);
    state = RESET_DEACTIVATED;
  endtask: wait_for_system_reset


  // TODO(mshariff): Put more comments for logic pf SCL and SDA

  task drive_idle_state();
    @(posedge pclk);
    scl_oen <= TRISTATE_BUF_OFF;
    scl_o   <= 1;
    sda_oen <= TRISTATE_BUF_OFF;
    sda_o   <= 1;
    state <= IDLE;
  endtask: drive_idle_state


  task wait_for_idle_state();
    @(posedge pclk);
    while(scl_i!=1 && sda_i!=1) begin
      @(posedge pclk);
    end
    state = IDLE;
    `uvm_info(NAME, $sformatf("I3C bus is free state detected"), UVM_HIGH);
  endtask: wait_for_idle_state


  task drive_data(inout i3c_transfer_bits_s p_data_packet, 
                  input i3c_transfer_cfg_s p_cfg_pkt);
  
    dataPacketStruck = p_data_packet;
    configPacketStruck = p_cfg_pkt;

    detect_start();

    sample_target_address(configPacketStruck,dataPacketStruck.targetAddressStatus);
    
    sample_operation(dataPacketStruck.operation);
    
    driveAddressAck(dataPacketStruck.targetAddressStatus);

    if(dataPacketStruck.targetAddressStatus == ACK) begin
      if(dataPacketStruck.operation == WRITE) begin
        sample_write_data(configPacketStruck,dataPacketStruck.writeDataStatus[0]);
        driveWdataAck(dataPacketStruck.writeDataStatus[0]);
      end else begin
        rdata = configPacketStruck.targetFIFOMemory.pop_front();
        drive_read_data(rdata);
        sample_ack(dataPacketStruck.readDataStatus[0]);
      end
    end else begin
      detect_stop();
    end
    detect_stop();
  endtask: drive_data
  

  task detect_start();
    // 2bit shift register to check the edge on sda and stability on scl
    bit [1:0] scl_local;
    bit [1:0] sda_local;

    state = START;
    // Detect the edge on scl
    do begin
      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};
      sda_local = {sda_local[0], sda_i};
    end while(!(sda_local == NEGEDGE && scl_local == 2'b11) );
    `uvm_info(NAME, $sformatf("Start condition is detected"), UVM_HIGH);
  endtask: detect_start


  task sample_target_address(input i3c_transfer_cfg_s cfg_pkt, output acknowledge_e ack);
    bit [6:0] local_addr;

    @(posedge pclk);
    state = ADDRESS;
    for(int k=0;k < 7; k++) begin
      detect_posedge_scl();
      local_addr[k] = sda_i;
      sda_oen <= TRISTATE_BUF_OFF;
      sda_o   <= 1;
    end

    `uvm_info(NAME, $sformatf("DEBUG :: Value of local_addr = %0x", local_addr[6:0]), UVM_NONE); 
    `uvm_info(NAME, $sformatf("DEBUG :: Value of target_address = %0x", cfg_pkt.targetAddress), UVM_NONE); 
   
    // Check if the sampled address belongs to this target
    if(local_addr[6:0] != 7'b1010101) begin
      ack = NACK;
    end
    else begin
      ack = ACK;
    end
  endtask: sample_target_address


  task sample_operation(output operationType_e wr_rd);
    bit operation;

    @(posedge pclk); 
    state = WR_BIT;
    detect_posedge_scl();
    operation = sda_i;
    sda_oen <= TRISTATE_BUF_OFF;
    sda_o   <= 1;

    if(operation == 1'b0) begin
      wr_rd = WRITE;
    end else begin
      wr_rd = READ;
    end
  endtask: sample_operation


  task driveAddressAck(input bit ack);
    @(posedge pclk); 
    state = ACK_NACK;
    detect_negedge_scl();
    drive_sda(ack); 
    repeat(2)
      @(posedge pclk); 
    sda_oen <= TRISTATE_BUF_OFF;
    sda_o   <= 1;
  endtask: driveAddressAck

  task driveWdataAck(input bit ack);
    @(posedge pclk); 
    state = ACK_NACK;
    detect_negedge_scl();
    drive_sda(ack); 
    repeat(2)
      @(posedge pclk); 
    sda_oen <= TRISTATE_BUF_OFF;
    sda_o   <= 1;
  endtask: driveWdataAck

  //-------------------------------------------------------
  // Task: detect_posedge_scl
  // Detects the edge on scl with regards to pclk
  //-------------------------------------------------------
  task detect_posedge_scl();
    // 2bit shift register to check the edge on scl
    bit [1:0] scl_local;
    edge_detect_e scl_edge_value;

    // default value of scl_local is logic 1
    scl_local = 2'b11;

    // Detect the edge on scl
    do begin
      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};
    end while(!(scl_local == POSEDGE));

    scl_edge_value = edge_detect_e'(scl_local);
    `uvm_info("target_DRIVER_BFM", $sformatf("scl %s detected", scl_edge_value.name()), UVM_HIGH);
  
  endtask: detect_posedge_scl
  
  //-------------------------------------------------------
  // Task: detect_negedge_scl
  // Detects the negative edge on scl with regards to pclk
  //-------------------------------------------------------
  task detect_negedge_scl();
    // 2bit shift register to check the edge on scl
    bit [1:0] scl_local;
    edge_detect_e scl_edge_value;

    // default value of scl_local is logic 1
    scl_local = 2'b11;

    // Detect the edge on scl
    do begin

      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};

    end while(!(scl_local == NEGEDGE));

    scl_edge_value = edge_detect_e'(scl_local);
    `uvm_info("target_DRIVER_BFM", $sformatf("scl %s detected", scl_edge_value.name()), UVM_HIGH);
  
  endtask: detect_negedge_scl


  //--------------------------------------------------------------------------------------------
  // Task: drive_sda 
  // Drive the logic sda value as '0' or '1' over the I3C inteerface using the tristate buffers
  //--------------------------------------------------------------------------------------------
  task drive_sda(input bit value);
    sda_oen <= value ? TRISTATE_BUF_OFF : TRISTATE_BUF_ON;
    sda_o   <= value;
  endtask: drive_sda


  task sample_write_data(inout i3c_transfer_cfg_s cfg_pkt, output acknowledge_e ack);
    bit [7:0] wdata;

    repeat(2) 
    //  @(posedge pclk);
    // GopalS: detect_negedge_scl();
    state = WRITE_DATA;
   // sda_oen <= TRISTATE_BUF_OFF;
   // sda_o   <= 1;

    for(int k=0;k < DATA_WIDTH; k++) begin
      detect_posedge_scl();
      wdata[k] = sda_i;
    end

    `uvm_info(NAME, $sformatf("DEBUG :: Value of sampled write data = %0x", wdata[7:0]), UVM_NONE); 
    cfg_pkt.targetFIFOMemory.push_back(wdata);
   
    ack = ACK;
  endtask: sample_write_data


  task drive_read_data(input bit[7:0] rdata);
    int bit_no;

    `uvm_info("DEBUG", $sformatf("Driving byte = %0b",rdata), UVM_NONE)
    state = READ_DATA;
    for(int k=0;k < DATA_WIDTH; k++) begin
      detect_negedge_scl();
      sda_oen <= TRISTATE_BUF_ON;
      sda_o   <= rdata[k];
      detect_posedge_scl();
    end
  endtask :drive_read_data


  task sample_ack(output bit ack);
    detect_negedge_scl();
    state    = ACK_NACK;
    ack     = sda_i;
    detect_posedge_scl();
  endtask :sample_ack


  task detect_stop();
    // 2bit shift register to check the edge on sda and stability on scl
    bit [1:0] scl_local;
    bit [1:0] sda_local;

    // Detect the edge on scl
    state = STOP;
    do begin
      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};
      sda_local = {sda_local[0], sda_i};
    end while(!(sda_local == POSEDGE && scl_local == 2'b11) );
    `uvm_info(NAME, $sformatf("Stop condition is detected"), UVM_HIGH);
  endtask: detect_stop
 /* 
  //--------------------------------------------------------------------------------------------
  // Task: sample_target_address
  // Samples the target address from the I3C bus 
  //
  // Parameters:
  //  address - The target address value (7bit or 10bit value)
  //
  // Returns:
  //  ack - Returns positive ack when the address matches with its target address, otherwise 
  //  returns negative ack
  //--------------------------------------------------------------------------------------------
  task sample_target_address(input i3c_transfer_cfg_s cfg_pkt, output acknowledge_e ack, output read_write_e wr_rd);
    bit [7:0] local_addr;

    state = ADDRESS;
    for(int k=0;k <= 7; k++) begin
      detect_posedge_scl();
      local_addr[k] = sda_i;
      sda_oen <= TRISTATE_BUF_OFF;
      sda_o   <= 1;
    end

    `uvm_info(name, $sformatf("DEBUG :: Value of local_addr = %0x", local_addr[6:0]), UVM_NONE); 
    `uvm_info(name, $sformatf("DEBUG :: Value of target_address = %0x", cfg_pkt.target_address), UVM_NONE); 
   
    // Check if the sampled address belongs to this target
    if(local_addr[6:0] != cfg_pkt.target_address) begin
      ack = NEG_ACK;
    end
    else begin
      ack = POS_ACK;
    end
 
    if(local_addr[7] == 1'b0) begin
      wr_rd = WRITE;
    end else begin
      wr_rd = READ;
    end
    // Driving the ACK for target address
    detect_negedge_scl();
    drive_sda(ack); 
    state = target_ADDR_ACK;
    detect_posedge_scl();

  endtask: sample_target_address

  //--------------------------------------------------------------------------------------------
  // Task: drive_sda 
  // Drive the logic sda value as '0' or '1' over the I3C inteerface using the tristate buffers
  //--------------------------------------------------------------------------------------------
  task drive_sda(input bit value);
    sda_oen <= value ? TRISTATE_BUF_OFF : TRISTATE_BUF_ON;
    sda_o   <= value;
  endtask: drive_sda


  //--------------------------------------------------------------------------------------------
  // Task: start_sim 
  // Drive the logic sda value as '0' or '1' over the I3C inteerface using the tristate buffers
  //--------------------------------------------------------------------------------------------
  task start_sim(input i3c_transfer_cfg_s cfg_pkt);

    acknowledge_e ack;
    read_write_e wr_rd;
    bit[7:0] rdata;

    //wait for the statrt condition
    detect_start();

    sample_target_address(cfg_pkt, ack, wr_rd);
    `uvm_info("DEBUG", $sformatf("target address %0x :: Received ACK %0s", 
                                       cfg_pkt.target_address, ack.name()), UVM_NONE); 

    // Proceed further only if the I3C packet is addressed to this target                                       
    if(ack == POS_ACK) begin
      if(wr_rd == WRITE) begin
        sample_write_data(cfg_pkt, ack);
      end else begin
        rdata = cfg_pkt.target_memory[cfg_pkt.target_address];
        drive_read_data(rdata);
        sample_ack(ack);
      end
    end else begin
      detect_stop();
    end
    detect_stop();
    
  endtask: start_sim

  task sample_write_data(input i3c_transfer_cfg_s cfg_pkt, output acknowledge_e ack);
    bit [7:0] wdata;

    state = WRITE_DATA;
    for(int k=0;k < DATA_WIDTH; k++) begin
      detect_posedge_scl();
      wdata[k] = sda_i;
      sda_oen <= TRISTATE_BUF_OFF;
      sda_o   <= 1;
    end

    `uvm_info(name, $sformatf("DEBUG :: Value of sampled write data = %0x", wdata[7:0]), UVM_NONE); 
    cfg_pkt.target_memory[cfg_pkt.target_address] = wdata;
   
    ack = POS_ACK;

    // Driving the ACK for target address
    detect_negedge_scl();
    drive_sda(ack); 
    state = target_ADDR_ACK;
    detect_posedge_scl();

  endtask: sample_write_data


  // task for driving the address byte and data byte
   task drive_read_data(input bit[7:0] p_data_8b);
     int bit_no;

     `uvm_info("DEBUG", $sformatf("Driving byte = %0b",p_data_8b), UVM_NONE)
      state = READ_DATA;
     for(int k=0;k < DATA_WIDTH; k++) begin
       scl_tristate_buf_on();
       sda_oen <= TRISTATE_BUF_ON;
       sda_o   <= p_data_8b[k];
       scl_tristate_buf_off();
     end
      
   endtask :drive_read_data


  // task for sampling the Acknowledge
   task sample_ack(output acknowledge_e p_ack);
     bit ack;
     @(posedge pclk);
     scl_oen <= TRISTATE_BUF_ON;
     scl_o   <= 0;

     sda_oen <= TRISTATE_BUF_OFF;
     sda_o   <= 1;
     state    = target_ADDR_ACK;

     @(posedge pclk);
     scl_oen <= TRISTATE_BUF_OFF;
     scl_o   <= 1;
     ack     = sda_i;

     `uvm_info(name, $sformatf("Sampled ACK value %0b",p_ack), UVM_MEDIUM);

     if(ack == 1'b0) begin
       p_ack = ACK;
     end else begin
       p_ack = NACK;
     end
   endtask :sample_ack

  
  //-------------------------------------------------------
  // Task: detect_stop
  // Detects the STOP condition over I3C bus
  //-------------------------------------------------------
  task detect_stop();
    // 2bit shift register to check the edge on sda and stability on scl
    bit [1:0] scl_local;
    bit [1:0] sda_local;

    // Detect the edge on scl
    state = STOP;
    do begin
      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};
      sda_local = {sda_local[0], sda_i};
    end while(!(sda_local == POSEDGE && scl_local == 2'b11) );
    `uvm_info(name, $sformatf("Stop condition is detected"), UVM_HIGH);
  endtask: detect_stop
  

  // task for driving the scl_oen as high and scl as low
  task scl_tristate_buf_on();
    @(posedge pclk);
    scl_oen <= TRISTATE_BUF_ON;
    scl_o   <= 0;
  endtask


  // task for driving the scl_oen as high and scl as low
  task scl_tristate_buf_off();
    @(posedge pclk);
    scl_oen <= TRISTATE_BUF_OFF;
    scl_o   <= 1;
  endtask
*/

`endif
endinterface : i3c_target_driver_bfm
