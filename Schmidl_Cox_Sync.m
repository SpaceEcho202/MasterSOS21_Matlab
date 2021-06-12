classdef Schmidl_Cox_Sync
    %SCHMIDL_COX_SYNC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TxInfo;
        Size;
        RxSignal;
    end
    methods
        % Is used as constructor to predefine class variables
        function obj = Schmidl_Cox_Sync()
            
            obj.TxInfo      = NumerlogyRefactoring();
            obj.Size        = [];
            obj.RxSignal    = [];
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
        function [PlateauLeftEdge, PlateauCenter, PlateauRightEdge...
                , M_d] = thresholder(varargin)
            [M_d, ~, ~] = time_metric_creator(varargin{:});
            Threshold = 1.0;
            [~,Index] = find(M_d >= Threshold);
            PlateauStartIndex = Index(1);
            PlateauEndIndex = Index(end);
            PlateauCenterIndex = ceil((PlateauEndIndex - PlateauStartIndex)/2);
            [PlateauLeftEdge,PlateauCenter, PlateauRightEdge] = deal(NaN(1,length(M_d)));       
            [PlateauLeftEdge(PlateauStartIndex),...
                PlateauRightEdge(PlateauEndIndex), ...
                PlateauCenter(PlateauStartIndex + PlateauCenterIndex)] = deal(Threshold);
        end
    end
    
    methods
        function [TimeAxisNorm, SampleAxis] = show_metric(varargin)
            [PlateauLeftEdge, PlateauCenter, PlateauRightEdge...
                , M_d] = thresholder(varargin{:});
            dt = (1/varargin{:}.TxInfo.SubcarrierSpacing)/...
                varargin{:}.Size;
            TimeAxis = linspace(0,dt*(length(M_d)), length(M_d));
            TimeAxisNorm = TimeAxis/1e-6; % normalized to mircoseconds
            SampleAxis = linspace(0,length(M_d), length(M_d));
            
            figure;            
            plot(SampleAxis, M_d), xlabel('Sample [Index]'), ylabel('M_d'),
            ax = gca;
            ax.XAxis.MinorTick = 'on';
            ax.XAxis.MinorTickValues = 0:200:SampleAxis(end);
            ylim([0 1.2]), xlim([0 SampleAxis(end)]), xlim([0 2*varargin{:}.Size]),
            title('S&C Timing Metric')
            hold on,
            stem(SampleAxis, PlateauLeftEdge,'.')
            stem(SampleAxis, PlateauCenter,'.')
            stem(SampleAxis, PlateauRightEdge,'.')
            legend('Time Metric','Left Edge',...
                'Centre AWGN Syncpoint', ...
                'Right Edge Frame Syncpoint','Location', 'southwest')
            hold off
        end
    end
end
