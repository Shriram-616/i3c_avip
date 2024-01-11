`ifndef I3C_READOPERATIONWITH8BITSDATA_STARTSTOPCOMBINATION_TEST_INCLUDED_
`define I3C_READOPERATIONWITH8BITSDATA_STARTSTOPCOMBINATION_TEST_INCLUDED_

class i3c_readOperationWith8bitsData_startStopCombination_test extends i3c_base_test;
  `uvm_component_utils(i3c_readOperationWith8bitsData_startStopCombination_test)

  i3c_virtual_readOperationWith8bitsData_startStopCombination_seq i3c_virtual_readOperationWith8bitsData_startStopCombination_seq_h;

  extern function new(string name = "i3c_readOperationWith8bitsData_startStopCombination_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : i3c_readOperationWith8bitsData_startStopCombination_test

function i3c_readOperationWith8bitsData_startStopCombination_test::new(string name = "i3c_readOperationWith8bitsData_startStopCombination_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void i3c_readOperationWith8bitsData_startStopCombination_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

task i3c_readOperationWith8bitsData_startStopCombination_test::run_phase(uvm_phase phase);

  i3c_virtual_readOperationWith8bitsData_startStopCombination_seq_h = i3c_virtual_readOperationWith8bitsData_startStopCombination_seq::type_id::create("i3c_virtual_readOperationWith8bitsData_startStopCombination_seq_h");

  phase.raise_objection(this);

  i3c_virtual_readOperationWith8bitsData_startStopCombination_seq_h.start(i3c_env_h.i3c_virtual_seqr_h); 
  #20;

  phase.drop_objection(this);

endtask : run_phase

`endif


