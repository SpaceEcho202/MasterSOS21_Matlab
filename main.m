%% This is our main.m whicht will be used to execute the TxStructure!
clc
clear all
close all
tic;
%% Send structure
TxStructure = NumerlogyRefactoring;
TxStructure.Bandwidth = 10e6;
TxStructure.ModulationOrder = 64;
TxStructure.ModulationOrderFirstPreamble = 64;
TxStructure.ModulationOrderSecondPreamble = 32;
% sended ofdm signal
TxSignal = TxStructure.tx_alligned_signal();
%% Synchronize structure
SyncStructure = Schmidl_Cox_Sync();
SyncStructure.RxSignal = TxSignal;
[~, SyncStructure.Size] = TxStructure.resource_blocks();
toc;
SyncStructure.show_metric();
%% Receive structure