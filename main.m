%% This is our main.m whicht will be used to execute the TxStructure and SnycStructure!
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
cfo_temp                                    = .05;
cfo                                         = -cfo_temp/Size;                                  % set carrier frequency offset
N                                           = linspace(0,length(TxSignal),length(TxSignal));   % samples in range length tx signal
Measurements                                = 100;                                             % measure count for sync validation            
SnrInDb                                     = linspace(10, 40, 31);                            % snr count for sync validation 
sigma_s2                                    = mean(abs(TxSignal.^2));
sigma_n2                                    = sigma_s2 * 10.^(-SnrInDb/10);
sigma_i2                                    = pi^2/12*sigma_s2*sin(pi*cfo_temp).^2;
SINR_reduction                              = 10*log10(1 + sigma_i2 ./ sigma_n2);
for MeasureIndex = 1:Measurements           
for SnrIndex = 1:length(SnrInDb)
SyncStructure                               = Schmidl_Cox_Sync();                                           % create synchronizer object
SyncStructure.RxSignal                      = awgn(TxSignal.*exp(1.i*2*pi*cfo*N),SnrInDb(SnrIndex));        % add lo-offset and awgn to tx signal 
[~, SyncStructure.Size]                     = TxStructure.resource_blocks();                                % get samples per resource element
CFO_max_detection                           = SyncStructure.cfo_estimator('max_plateau_detector');
CFO_ninety_detection                        = SyncStructure.cfo_estimator('ninety_percent_detector');
CFO_threshold_detection                     = SyncStructure.cfo_estimator('threshold_detector');
CFO_Error_max(MeasureIndex, SnrIndex)       = (abs(cfo_temp - CFO_max_detection )/cfo_temp)*100;     
CFO_Error_ninety(MeasureIndex, SnrIndex)    = (abs(cfo_temp - CFO_ninety_detection )/cfo_temp)*100;         %
CFO_Error_threshold(MeasureIndex, SnrIndex) = (abs(cfo_temp - CFO_threshold_detection )/cfo_temp)*100;
end
end

CFO_Error_mean_1                            = mean(CFO_Error_max,1);
CFO_Error_mean_2                            = mean(CFO_Error_ninety,1);
CFO_Error_mean_3                            = mean(CFO_Error_threshold,1);

semilogy(SnrInDb, CFO_Error_mean_1,'b-*',...
         SnrInDb, CFO_Error_mean_2,'r-*',...
         SnrInDb, CFO_Error_mean_3,'g-*',...
            'MarkerIndices', 1:1:length(SnrInDb))
        
     xlabel('SNR [dB]')
     ylabel('Error [%]')
     title(['CFO Measurements: ' num2str(Measurements)])
     legend('Sync 90% Detect Error_{mean}',...
            'Sync Max Detect Error_{mean}',...
            'Sync Thr Detect Error_{mean}','southwest')
     grid on
     
toc;
SyncStructure.show_metric();
%% Receive structure