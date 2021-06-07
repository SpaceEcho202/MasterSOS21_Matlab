%% This is our main.m whicht will be used to execute the simulation!
clc
clear all
tic;
Simulation = NumerlogyRefactoring;
Simulation.Bandwidth = 1.4e6;
Simulation.ModulationOrder = 256;
Simulation.show_alligned_tx_signal;
Simulation.show_grid();
TxFrameCP = Simulation.cycle_prefixer();
toc;
