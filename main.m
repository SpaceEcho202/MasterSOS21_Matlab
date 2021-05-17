%% This is our main.m whicht will be used to execute the simulation!

clc
clear all

SequenceLength = 1024;
SeedPRBS = 1;

Simulation = Numerlogy;

Simulation.ModulationOrder      = 256;
Simulation.ResourceElementCount = 12;
Simulation.SeedPRBS             = 0;

complexSymbols = Simulation.symbol_mapper();
ifft = Simulation.ifft_signal();