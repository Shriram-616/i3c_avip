`ifndef I3C_CONTROLLER_RANDOMOPERATIONWITHRANDOMDATATRANSFERWIDTH_SEQ_INCLUDED_
`define I3C_CONTROLLER_RANDOMOPERATIONWITHRANDOMDATATRANSFERWIDTH_SEQ_INCLUDED_

class i3c_controller_randomOperationWithRandomDataTransferWidth_seq extends i3c_controller_base_seq;
  `uvm_object_utils(i3c_controller_randomOperationWithRandomDataTransferWidth_seq)

  extern function new(string name = "i3c_controller_randomOperationWithRandomDataTransferWidth_seq");
  extern task body();
endclass : i3c_controller_randomOperationWithRandomDataTransferWidth_seq

function i3c_controller_randomOperationWithRandomDataTransferWidth_seq::new(string name = "i3c_controller_randomOperationWithRandomDataTransferWidth_seq");
  super.new(name);
endfunction : new


task i3c_controller_randomOperationWithRandomDataTransferWidth_seq::body();
  super.body();

  req = i3c_controller_tx::type_id::create("req"); 

  start_item(req);
    if(!req.randomize() with {targetAddress == 7'b1010101;}) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
  
    req.print();
  finish_item(req);

endtask:body
  
`endif


