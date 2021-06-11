%% This is our main.m whicht will be used to execute the TxStructure!
clc
clear all
close all
tic;
%% Send structure
TxStructure = NumerlogyRefactoring;
TxStructure.Bandwidth = 1.4e6;
TxStructure.ModulationOrder = 4;
TxStructure.ModulationOrderFirstPreamble = 64;
TxStructure.ModulationOrderSecondPreamble = 32;
% sended ofdm signal
TxSignal = TxStructure.tx_alligned_signal();
%% Synchronize structure
SyncStructure = Schmidl_Cox_Sync();
SyncStructure.RxSignal = TxSignal;
SyncStructure.PreambleLength = 64;
% SyncStructure.preamble_corr();
SyncStructure.show_metric();
toc;
%% Receive structure