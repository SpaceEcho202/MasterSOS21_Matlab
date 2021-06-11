classdef Schmidl_Cox_Sync
    %SCHMIDL_COX_SYNC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PreambleLength;
        RxSignal;
    end
    methods
        % Is used as constructor to predefine class variables
        function obj = Schmidl_Cox_Sync()
            obj.PreambleLength = [];
            obj.RxSignal       = [];
        end
    end
    methods
        function P_d = preamble_corr(varargin)
            r = varargin{:}.RxSignal;
            PP = 0;
            RR = 0;
            L = varargin{:}.PreambleLength;
            for m = 1:L
                P = sum(conj(r(m))*r(m+L));
                P = P+PP;
                R = sum(abs(r(m+L))^2);
                R = R+RR;
            end
            R = RR;
            P = PP;
            for d = 1:length(r)-2*L
                P(d+1) = P(d)+conj(r(d+L))*r(d+2*L)...
                    -conj(r(d))*r(d+L);
                R(d+1) = R(d)+(abs(r(d+(2*L))).^2)...
                    -abs(r(d+L))^2;
            end
            M = (abs(P).^2)./((R).^2);
            P_d = M;
        end
    end
    
    methods
        function show_metric(varargin)
            figure;
            P_d = preamble_corr(varargin{:});
            plot(linspace(0,length(P_d),length(P_d)), P_d)
        end
    end
end
   
