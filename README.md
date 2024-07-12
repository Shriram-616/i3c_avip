# Accelerated VIP for I3C Protocol
The idea of using Accelerated VIP is to push the synthesizable part of the testbench into the separate top module along with the interface and it is named as HDL TOP and the unsynthesizable part is pushed into the HVL TOP. This setup provides the ability to run the longer tests quickly. This particular testbench can be used for the simulation as well as the emulation based on mode of operation.


## Key Features 
1. It supports a two-wire serial interface up to 12.5 MHz.
2. Supports all MIPI I3C device types. 
3. Supports single controller-target
4. Legacy I2C Device coexistence on the same bus.
5. 7-bit configurable Target Address
6. Support multiple write-read operation
7. Support a maximum of 128 Byte of data transfer
8. Support data transfer MSB first and LSB first
9. backward compatibility with I2C

   
## Testbench Architecture Diagram
![image](https://github.com/mbits-mirafra/i3c_avip/assets/106074838/32227a76-6131-42aa-8a01-6db2b224aba1)


## Developers, Welcome
We believe in growing together and if you'd like to contribute, please do check out the contributing guide below:  
https://github.com/mbits-mirafra/i3c_avip/blob/production/contribution_guidelines.md

## Installation - Get the VIP collateral from the GitHub repository

```
# Checking for git software, open the terminal type the command
git version

# Get the VIP collateral
git clone git@github.com/mbits-mirafra/i3c_avip.git
```

## Running the test

### Using Mentor's Questasim simulator 

```
cd i3c_avip/sim/questasim

# Compilation:  
make compile

# Simulation:
make simulate test=<test_name> uvm_verbosity=<VERBOSITY_LEVEL>

ex: make simulate test=i3c_writeOperationWith8bitsData_test uvm_verbosity=UVM_HIGH

# Note: You can find all the test case names in the path given below
i3c_avip/src/hvl_top/testlists/i3c_standard_mode_regression.list 

# Wavefrom:  
vsim -view <test_name>/waveform.wlf &

ex: vsim -view i3c_writeOperationWith8bitsData_test/waveform.wlf &

# Regression:
make regression testlist_name=<regression_testlist_name.list>
ex: make regression testlist_name=i3c_standard_mode_regression.list

# Coverage: 
 ## Individual test:
 firefox <test_name>/html_cov_report/index.html &
 ex: firefox i3c_writeOperationWith8bitsData_test/html_cov_report/index.html &

 ## Regression:
 firefox merged_cov_html_report/index.html &

```
### Using Synopsys VCS simulator 
```
cd i3c_avip/sim/synopsys_sim

# Compilation:  
make compile

# Simulation:
make simulate test=<test_name> uvm_verbosity=<VERBOSITY_LEVEL>

ex: make simulate test=i3c_writeOperationWith16bitsData_test uvm_verbosity=UVM_HIGH

# Wavefrom:  

ex: verdi -ssf novas.fsdb


```
### Latest regression coverage report link

https://github.com/mbits-mirafra/i3c_avip/issues/33#issuecomment-1933963627


### Using Cadence's Xcelium simulator 

```
cd i3c_avip/sim/cadence_sim

# Compilation:  
make compile
ex: make simulate test=i3c_writeOperationWith8bitsData_test uvm_verbosity=UVM_HIGH

# Note: You can find all the test case names in the path given below   
i3c_avip/src/hvl_top/testlists/i3c_standard_mode_regression.list

# Wavefrom:  
simvision waves.shm/ &

# Regression:
make regression testlist_name=<regression_testlist_name.list>
ex: make regression testlist_name=i3c_standard_mode_regression.list

# Coverage:   
imc -load cov_work/scope/test/ &
```

## I3C interface waveform 
![MicrosoftTeams-image (2)](https://github.com/mbits-mirafra/i3c_avip/assets/15922511/871de625-dcdf-42f8-9ec6-c2dd19b3619b)


## Technical Document 
https://docs.google.com/document/d/1UH9p83ARZM5K0v1wrA2lv7KpHbaGHC3u/

## Demonstrated backward compatibility to I2C RTL Controller

![image](https://github.com/mbits-mirafra/pulpino__i2c_master__ip_verification/assets/106074838/2fc6d151-9bd1-4d8c-b766-bafb54014bb1)

Follow the below link for the backward compatibility to I2C RTL Controller  
https://github.com/mbits-mirafra/pulpino__i2c_master__ip_verification


## Contact Mirafra Team  
You can reach out to us over mbits@mirafra.com

For more information regarding Mirafra Technologies please do checkout our officail website:  
https://mirafra.com/

