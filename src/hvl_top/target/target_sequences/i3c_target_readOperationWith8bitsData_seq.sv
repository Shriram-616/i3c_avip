`ifndef I3C_TARGET_READOPERATIONWITH8BITSDATA_SEQ_INCLUDED_ 
`define I3C_TARGET_READOPERATIONWITH8BITSDATA_SEQ_INCLUDED_

class i3c_target_readOperationWith8bitsData_seq extends i3c_target_base_seq;
  `uvm_object_utils(i3c_target_readOperationWith8bitsData_seq)

   extern function new(string name = "i3c_target_readOperationWith8bitsData_seq");
   extern task body();
endclass : i3c_target_readOperationWith8bitsData_seq

function i3c_target_readOperationWith8bitsData_seq::new(string name = "i3c_target_readOperationWith8bitsData_seq");
  super.new(name);
endfunction : new

task i3c_target_readOperationWith8bitsData_seq::body();
//  super.body();

// Mahadeva:  req.i3c_target_agent_cfg_h = p_sequencer.i3c_target_agent_cfg_h;

//  `uvm_info("DEBUG", $sformatf("address = %0x",
//  p_sequencer.i3c_target_agent_cfg_h.slave_address_array[0]), UVM_NONE)

  req = i3c_target_tx::type_id::create("req"); 

  start_item(req);

  if(!req.randomize()) begin
    `uvm_error(get_type_name(), "Randomization failed")
  end

  req.print();
  finish_item(req);

endtask:body

`endif


