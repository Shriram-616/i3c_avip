`ifndef I3C_TARGET_MONITOR_BFM_INCLUDED_
`define I3C_TARGET_MONITOR_BFM_INCLUDED_

import i3c_globals_pkg::*; 

interface i3c_target_monitor_bfm(input pclk, 
                                input areset, 
                                input scl_i,
                                input scl_o,
                                input scl_oen,
                                input sda_i,
                                input sda_o,
                                input sda_oen);

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import i3c_target_pkg::*;
  import i3c_target_pkg::i3c_target_monitor_proxy;
  
  i3c_target_monitor_proxy i3c_target_mon_proxy_h; 
  i3c_fsm_state_e state;

  string name = "I3C_TARGET_MONITOR_BFM";
  initial begin
    $display("target Monitor BFM");
  end
 
  task wait_for_reset();
    @(negedge areset);
    @(posedge areset);
  endtask: wait_for_reset

  task sample_idle_state();
    @(posedge pclk);
  endtask: sample_idle_state
  
  task wait_for_idle_state();
    @(posedge pclk);
    while(scl_i!=1 && sda_i!=1) begin
     @(posedge pclk);
    end
    state = IDLE;
  endtask: wait_for_idle_state
  
  task sample_data(inout i3c_transfer_bits_s struct_packet,inout i3c_transfer_cfg_s struct_cfg);

    detect_start();
    sample_target_address(struct_packet);
    sample_operation(struct_packet.operation);
    sampleAddressAck(struct_packet.targetAddressStatus);
    if(struct_packet.targetAddressStatus == ACK) begin
      if(struct_packet.operation == WRITE) begin
      fork
        begin
          for(int i=0;i<MAXIMUM_BYTES;i++) begin
            sample_write_data(struct_packet,i);
            sampleWdataAck(struct_packet.writeDataStatus[i]);
            if(struct_packet.writeDataStatus[i] == NACK)
                break;
          end
        end
      join_none

      wrDetect_stop();
      disable fork;

      end else begin
        fork
          begin
            for(int i=0;i<MAXIMUM_BYTES;i++) begin
              sample_read_data(struct_packet,i);
              sample_ack(struct_packet.readDataStatus[i]);
              if(struct_packet.readDataStatus[i] == NACK)
                break;
            end
          end
        join_none

        wrDetect_stop();
        disable fork;
        end
      end else begin
      detect_stop();
    end
  endtask: sample_data
  

  task detect_start();
    bit [1:0] scl_local;
    bit [1:0] sda_local;
    state = START;
  
    do begin
      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};
      sda_local = {sda_local[0], sda_i};
    end while(!(sda_local == NEGEDGE && scl_local == 2'b11) );
  endtask: detect_start
  

  task sample_target_address(inout i3c_transfer_bits_s pkt);
    bit [TARGET_ADDRESS_WIDTH-1:0] address;
    state = ADDRESS;
    for(int k=0;k < 7; k++) begin
      detectEdge_scl(POSEDGE);
      address[k] = sda_i;
    end
    pkt.targetAddress = address;
  endtask: sample_target_address
  

  task sample_operation(output operationType_e wr_rd);
    bit operation;
    state = WR_BIT;
    detectEdge_scl(POSEDGE);
    operation = sda_i;
   if(operation == 0)
     wr_rd = WRITE;
   else
     wr_rd = READ;
  endtask: sample_operation
  

  task sampleAddressAck(output bit ack);
    state = ACK_NACK;
    detectEdge_scl(POSEDGE);
    ack = sda_i;
  endtask: sampleAddressAck
  

  task sample_write_data(inout i3c_transfer_bits_s pkt, input int i);
    bit[DATA_WIDTH-1:0] wdata;
    state = WRITE_DATA;
    for(int k=DATA_WIDTH-1; k>=0; k--) begin
      detectEdge_scl(POSEDGE);
      wdata[k] = sda_i;
      pkt.no_of_i3c_bits_transfer++;
    end
    pkt.writeData[i] = wdata;
  endtask: sample_write_data
  

  task sampleWdataAck(output bit ack);
    state = ACK_NACK;
    detectEdge_scl(POSEDGE);
    ack = sda_i;
  endtask: sampleWdataAck
  

  task sample_read_data(inout i3c_transfer_bits_s pkt,input int i);
    bit [DATA_WIDTH-1:0] rdata;
    state = READ_DATA;
    for(int k=DATA_WIDTH-1; k>=0; k--) begin
      detectEdge_scl(POSEDGE);
      rdata[k] = sda_i;
      pkt.no_of_i3c_bits_transfer++;
    end
    pkt.readData[i] = rdata;
  endtask :sample_read_data
  

  task sample_ack(output bit ack);
    state    = ACK_NACK;
    detectEdge_scl(POSEDGE);
    ack = sda_i;
  endtask :sample_ack
  

  task wrDetect_stop();
    // 2bit shift register to check the edge on sda and stability on scl
    bit [1:0] scl_local;
    bit [1:0] sda_local;

    do begin
      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};
      sda_local = {sda_local[0], sda_i};
    end while(!(sda_local == POSEDGE && scl_local == 2'b11) );
    state = STOP;
    `uvm_info(name, $sformatf("Stop condition is detected"), UVM_HIGH);
  endtask: wrDetect_stop
  

  task detect_stop();
    bit [1:0] scl_local;
    bit [1:0] sda_local;
    state = STOP;
  
    do begin
      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};
      sda_local = {sda_local[0], sda_i};
    end while(!(sda_local == POSEDGE && scl_local == 2'b11) );
  endtask: detect_stop
  

  task detectEdge_scl(input edge_detect_e edgeSCL);
    // 2bit shift register to check the edge on scl
    bit [1:0] scl_local;
    edge_detect_e scl_edge_value;
    // default value of scl_local is logic 1
    scl_local = 2'b11;

    do begin
      @(negedge pclk);
      scl_local = {scl_local[0], scl_i};
    end while(!(scl_local == edgeSCL));

    scl_edge_value = edge_detect_e'(scl_local);
    `uvm_info("TARGET_DRIVER_BFM", $sformatf("scl %s detected", scl_edge_value.name()), UVM_HIGH);
  endtask: detectEdge_scl
  

endinterface : i3c_target_monitor_bfm

`endif
