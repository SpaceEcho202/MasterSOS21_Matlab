%% This is our main.m whicht will be used to execute the simulation!
clc
clear all
close all
tic;
Simulation = NumerlogyRefactoring;
Simulation.Bandwidth = 1.4e6;
Simulation.ModulationOrder = 4;
Simulation.ModulationOrderFirstPreamble = 64;
Simulation.ModulationOrderSecondPreamble = 32;
Simulation.show_alligned_tx_signal();
Simulation.show_grid();
toc;
