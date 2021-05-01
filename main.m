%% This is our main.m whicht will be used to execute the simulation!

clc
clear all

SequenceLength = 1024;
SeedPRBS = 1;
ModulationOrder = 64;

BitStream = nrPRBS(SeedPRBS, SequenceLength)';

ComplexSymbols = Numerlogy.symbol_mapper(BitStream, ModulationOrder);

fprintf("gray-coded-complex-symbolstream: \n");
fprintf('%f%+fj\n', real(ComplexSymbols),imag(ComplexSymbols));
