classdef Schmidl_Cox_Sync
    %SCHMIDL_COX_SYNC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TxInfo;
        Size;
        RxSignal;
        Calibration;
    end
    methods
        % Is used as constructor to predefine class variables
        function obj = Schmidl_Cox_Sync()
            
            obj.TxInfo      = NumerlogyRefactoring();
            obj.Calibration = 1e3;
            obj.Size        = [];
            obj.RxSignal    = [];
        end
    end
    methods
        function [M_d_CalMean, M_d_CalStd,...
                M_d_mean_n, M_d_mean_p,...
                SnrInDbs, M_d_Send] = sync_calibration(varargin)
            cal = NumerlogyRefactoring();
            cal.Bandwidth = 10e6;
            cal.ModulationOrder = 64;
            cal.ModulationOrderFirstPreamble = 64;
            cal.ModulationOrderSecondPreamble = 32;
            tic;
            h = waitbar(0,'Calibration please wait...');
            SnrInDbs = linspace(-10,40,50);          
            for Index = 1:varargin{:}.Calibration
                waitbar(Index / varargin{:}.Calibration)
                TxFrame(Index,:) = cal.tx_alligned_signal();           
                for SnrIndex = 1:length(SnrInDbs)
                    RxFrame = awgn(TxFrame(Index,:), SnrInDbs(SnrIndex));         
                    varargin{:}.RxSignal = RxFrame;
                    [M_d, ~, ~] = time_metric_creator(varargin{:});
                    M_d_Send(SnrIndex,:) = M_d;
                    M_d_Cal(Index, SnrIndex) = M_d(1150);
                end
            end
            M_d_CalMean = mean(M_d_Cal);
            M_d_CalStd = std(M_d_Cal);
            M_d_mean_n = M_d_CalMean-(3*M_d_CalStd);
            M_d_mean_p = M_d_CalMean+(3*M_d_CalStd);
            close(h)
            toc;
        end
    end
    
    methods
        function [M_d, R_d, P_d] = time_metric_creator(varargin)
            RxSequence = varargin{:}.RxSignal;
            denumerator = [1, -1];
            numerator = [1, zeros(1,varargin{:}.Size/2-2), -1];
            SequenceOne = RxSequence(varargin{:}.Size/2+1:end);
            SequenceTwo = RxSequence(1:end-varargin{:}.Size/2);
            Correlation = [zeros(1, varargin{:}.Size/2),...
                conj(SequenceOne).*SequenceTwo];
            P_d = filter(numerator, denumerator, Correlation);
            R_d = filter(numerator, denumerator, abs(RxSequence).^2);
            M_d = (abs(P_d).^2)./((R_d).^2);
        end
    end
    methods
        function CFO = cfo_estimator(varargin)
            [PlateauLeftEdge, PlateauCenter, PlateauRightEdge... 
                , ~, P_d] = thresholder(varargin{:});
            ComplexValue = P_d(~isnan(PlateauRightEdge));      
            Phase = atan2(imag(ComplexValue), real(ComplexValue));
            CFO = 1-(Phase/pi);
        end
    end
    
    methods
        function [PlateauLeftEdge, PlateauCenter, PlateauRightEdge...
                , M_d, P_d]      = thresholder(varargin)
            [M_d, ~, P_d]        = time_metric_creator(varargin{:});
           
            M_d_temp             = M_d;
            [maxValue, maxIndex] = max(M_d);
            [~, leftEdgeIndex]   = min(abs(M_d_temp(1:maxIndex)-(.9*maxValue)));
            [~, rightEdgeIndex]  = min(abs(M_d_temp(maxIndex:end)-(.9*maxValue)));
            
            PlateauStartIndex    = leftEdgeIndex;
            PlateauEndIndex      = rightEdgeIndex + maxIndex;
            PlateauCenterIndex   = ceil((PlateauEndIndex + PlateauStartIndex)/2);
            
            [PlateauLeftEdge, PlateauCenter, PlateauRightEdge] = deal(NaN(1,length(M_d)));       
            [PlateauLeftEdge(PlateauStartIndex),...
                PlateauRightEdge(PlateauEndIndex), ...
                PlateauCenter(PlateauStartIndex + PlateauCenterIndex)] = deal(maxValue);
        end
    end
    methods
        function show_lookup_table(varargin)
            [M_d_CalMean, M_d_CalStd,...
                M_d_mean_n, M_d_mean_p,...
                SnrInDbs, M_d_Send] = sync_calibration(varargin{:});
            figure;
            subplot(1,2,1)
            plot(SnrInDbs, M_d_CalMean,'b', SnrInDbs, M_d_mean_n, '--r',...
                 SnrInDbs ,M_d_mean_p, '--r'), ylim([0 1]), xlabel('SNR [dB]')
            ylabel('Threshold'), title('S&C vs. SNR'), legend('M_d mean', 'M_d +std'...
                ,'M_d -std','Location', 'southwest')
            subplot(1,2,2)
            plot(linspace(0,length(M_d_Send),length(M_d_Send)),M_d_Send),
            xlim([0 2*varargin{:}.Size]), xlabel('Sample [Index]'), 
            ylabel('Threshold'), title('S&C Timing Metric vs. SNR')
        end
    end
    
    methods
        function [TimeAxisNorm, SampleAxis] = show_metric(varargin)
            [PlateauLeftEdge, PlateauCenter, PlateauRightEdge...
                , M_d, P_d] = thresholder(varargin{:});
            dt = (1/varargin{:}.TxInfo.SubcarrierSpacing)/...
                varargin{:}.Size;
            Phase = atan2(imag(P_d), real(P_d));
            TimeAxis = linspace(0,dt*(length(M_d)), length(M_d));
            TimeAxisNorm = TimeAxis/1e-6; % normalized to mircoseconds
            SampleAxis = linspace(0,length(M_d), length(M_d));
            
            figure;
            subplot(2,1,1)
            plot(SampleAxis, M_d), xlabel('Sample [Index]'), ylabel('M(d)'),
            ax = gca;
            ax.XAxis.MinorTick = 'on';
            ax.XAxis.MinorTickValues = 0:200:SampleAxis(end);
            ylim([0 max(PlateauRightEdge)]), xlim([0 SampleAxis(end)]), xlim([0 2*varargin{:}.Size]),
            title('S&C Timing Metric')
            hold on,
            stem(SampleAxis, PlateauLeftEdge,'.')
            stem(SampleAxis, PlateauCenter,'.')
            stem(SampleAxis, PlateauRightEdge,'.')
            legend('Time Metric','Left Edge',...
                'Centre AWGN Syncpoint', ...
                'Right Edge Frame Syncpoint','Location', 'southeast')
            hold off
            subplot(2,1,2)
            plot(SampleAxis, Phase), xlabel('Sample [Index]'), ylabel('Arg(P(d))'),
            ax = gca;
            ax.XAxis.MinorTick = 'on';
            ax.XAxis.MinorTickValues = 0:200:SampleAxis(end);
            ylim([-pi pi]), xlim([0 SampleAxis(end)]), xlim([0 2*varargin{:}.Size]),
            yticks([-pi -pi*3/4, -pi/2, 0, pi/2, pi*3/4 pi]) 
            yticklabels({'-\pi', '-\pi3/4', '-\pi/2','0', '\pi/2', '\pi3/4', '\pi'})
            title('S&C Phase')
            hold on
            stem(SampleAxis, PlateauLeftEdge*pi,'.')
            stem(SampleAxis, PlateauCenter*pi,'.')
            stem(SampleAxis, PlateauRightEdge*pi,'.')
            legend('Phase','Left Edge',...
                'Centre AWGN Syncpoint', ...
                'Right Edge Frame Syncpoint','Location', 'southeast')
            hold off
        end
    end
end
