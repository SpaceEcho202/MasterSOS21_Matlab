%% This is our main.m whicht will be used to execute the TxStructure and SnycStructure!
clc
clear all
close all
tic;
DataX = linspace(0,0.5,100);
Test = 10*log10((10/(3*log(10)))*(pi*1024*DataX).^2);

db = 20./((pi^2/12*20*sin(pi*DataX).^2) + 5)
SINR_reduction = 1+ (pi^2/12*20*sin(pi*DataX).^2)/5 

%% Send structure
TxStructure                                 = NumerlogyRefactoring;                     % create numerlogy object
TxStructure.Bandwidth                       = 10e6;                                     % set bandwidth
TxStructure.ModulationOrder                 = 64;                                       % set modulation order *all resources are same*
TxStructure.ModulationOrderFirstPreamble    = 64;                                       % set first preamble modulation
TxStructure.ModulationOrderSecondPreamble   = 32;                                       % set second preamble modulation
TxSignal                                    = TxStructure.tx_alligned_signal();         % get tx signal from numerlogy settings 
%% Synchronize structure
[~, Size]                                   = TxStructure.resource_blocks();
cfo_temp                                    = .01;
cfo                                         = -cfo_temp/Size;                                 % set carrier frequency offset
N                                           = linspace(0,length(TxSignal),length(TxSignal));  % samples in range length tx signal
Measurements                                = 100;                                            % measure count for sync validation            
SnrInDb                                     = linspace(5, 30, 100);                           % snr count for sync validation 
sigma_s2                                    = mean(abs(TxSignal.^2));
sigma_n2                                    = sigma_s2 * 10.^(-SnrInDb/10);
sigma_i2                                    = pi^2/12*sigma_s2*sin(pi*cfo_temp).^2;
SINR_reduction                              = 10*log10(1 + sigma_i2 ./ sigma_n2);
for MeasureIndex = 1:Measurements           
for SnrIndex = 1:length(SnrInDb)
SyncStructure                               = Schmidl_Cox_Sync();                                           % create synchronizer object
SyncStructure.RxSignal                      = awgn(TxSignal.*exp(1.i*2*pi*cfo*N),SnrInDb(SnrIndex));        % add lo-offset and awgn to tx signal 
[~, SyncStructure.Size]                     = TxStructure.resource_blocks();                                % get samples per resource element
CFO_Error(MeasureIndex, SnrIndex)           = (abs(cfo_temp - SyncStructure.cfo_estimator())/cfo_temp)*100; % 
end
end
CFO_Error_mean                              = mean(CFO_Error,1);
semilogy(SnrInDb, CFO_Error_mean,'r-d')
     xlabel('SNR [dB]')
     ylabel('Error [%]')
     legend('CFO Error_{mean}','CFO Error_{std}')
     grid on
     minor on
toc;
SyncStructure.show_metric();
%% Receive structure