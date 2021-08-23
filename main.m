%% This is our main.m whicht will be used to execute the TxStructure!
clc
clear all
close all
tic;
%% Send structure
TxStructure                                 = NumerlogyRefactoring;                     % create numerlogy object
TxStructure.Bandwidth                       = 10e6;                                     % set bandwidth
TxStructure.ModulationOrder                 = 64;                                       % set modulation order *all resources are same*
TxStructure.ModulationOrderFirstPreamble    = 64;                                       % set first preamble modulation
TxStructure.ModulationOrderSecondPreamble   = 32;                                       % set second preamble modulation
TxSignal                                    = TxStructure.tx_alligned_signal();         % get tx signal from numerlogy settings 
%% Synchronize structure
[~, Size]                                   = TxStructure.resource_blocks();
cfo                                         = .01/Size;                                     % set carrier frequency offset
N                                           = linspace(0,length(TxSignal),length(TxSignal));% samples in range length tx signal
SyncStructure                               = Schmidl_Cox_Sync();                           % create synchronizer object
SyncStructure.RxSignal                      = awgn(TxSignal.*exp(1.i*2*pi*cfo*N),15);       % add lo-offset and awgn to tx signal 
[~, SyncStructure.Size]                     = TxStructure.resource_blocks();                % 
toc;
SyncStructure.cfo_estimator()
SyncStructure.show_metric();
%% Receive structure