classdef NumerlogyRefactoring
    % Numerlogy Class is used to assigne subcarrier to dedicated bandwidth
    % This class will perform all steps to create signal vector and
    % frames
    
    properties
        Bandwidth;                      % Used transmission bandwidth
        ModulationOrder;                % Used for quadrature modulation
        Coderate;                       % Used code rate *not implemented*
        FrameCount;                     % How many frames will be uses *not implemented*
        SubcarrierPerRescourceBlock ;   % Smallest assignable unit in grid
        SeedPRBS;                       % Seed to reproduce bit sequence
        SubcarrierSpacing;              % Used to set \delta f between adjacent carriers
        CyclicPrefixLength;             % Used to set the cyclixc extension of one OFDM symbol
        SymbolsPerResourceElement;      % Used to determine how many symbols fit in one element
        SlotCount;                      % Used to set how many slots will fit in one element
        FirstPolynomal;                 % x1_init = Used to create gold sequence *not implemnented*
        SecondPolynomal;                % x2_init = Used to create gold sequence *not implemnented*
        PreambleBoostFactor             % Used to boost the synchronizer preamble *not implemented*
        
    end
    
    methods
        % Is used as constructor to predefine class variables
        function obj                                = NumerlogyRefactoring()
            obj.Bandwidth                           = 1.4e6;
            obj.ModulationOrder                     = 4;
            obj.Coderate                            = [];
            obj.FrameCount                          = 1;
            obj.SubcarrierPerRescourceBlock         = 12;
            obj.SeedPRBS                            = 401;
            obj.SubcarrierSpacing                   = 15e3;
            obj.CyclicPrefixLength                  = 1/4;
            obj.SymbolsPerResourceElement           = 7;
            obj.SlotCount                           = 2;
            obj.FirstPolynomal                      = [];
            obj.SecondPolynomal                     = [];
            obj.PreambleBoostFactor                 = [];
        end
    end
    
    methods
        function [ResourceBlockCount, FFTSize] = resource_blocks(varargin)
            if (nargin ~= 1)
                Bandwidth_ = varargin{1,2};
            else
                Bandwidth_ = varargin{1}.Bandwidth;
            end
            switch Bandwidth_
                case 1.4e6
                    ResourceBlockCount = 6;
                    FFTSize = 128;
                case 3e6
                    ResourceBlockCount = 15;
                    FFTSize = 256;
                case 5e6
                    ResourceBlockCount = 25;
                    FFTSize = 512;
                case 10e6
                    ResourceBlockCount = 50;
                    FFTSize = 1024;
                otherwise
                    ResourceBlockCount = empty;
                    FFTSize = empty;
            end
        end
    end
    
    methods
        % Method to create a pseudo random bit sequence depending on how many
        % recource elements are used or which length is passed as argument
        function BitStream = bit_stream(varargin)
            if (nargin ~= 1)
                [BitStreamLength_, SeedPRBS_] = varargin{1,2:3};
            else
                SeedPRBS_ = varargin{1}.SeedPRBS;
                BitStreamLength_ = log2(varargin{1}.ModulationOrder)...
                    *varargin{1}.SubcarrierPerRescourceBlock...
                    *resource_blocks(varargin{:})*varargin{1}.SymbolsPerResourceElement;
            end
            BitStream = nrPRBS(SeedPRBS_, BitStreamLength_)';
        end
    end
    
    methods
        % Method to encode a parsed logical bitstream into graycoded symbols
        % depending on parsed modulation order
        function ComplexSymbols = symbol_mapper(varargin)
            if (nargin ~= 1)
                [ModulationOrder_, BitStream_] = varargin{1,1:2}; % Maybe you need to change all varargin{1,2:3} to varargin{1,1:*}
            else                                                  % *end_number of passed arguments
                ModulationOrder_ = varargin{1}.ModulationOrder;
                BitStream_ = bit_stream(varargin{:});
            end
            BitPerSymbol = log2(ModulationOrder_);
            SymbolsInBitStream = length(BitStream_)/BitPerSymbol;
            DecStream = zeros(SymbolsInBitStream , 1);
            for Index = 1:SymbolsInBitStream
                DecStream(Index,:) = bin2dec(num2str(BitStream_(1:BitPerSymbol)));
                BitStream_(1:BitPerSymbol) = [];
            end
            ComplexSymbols = qammod(DecStream', ModulationOrder_ ,'gray');
        end
    end
    
    methods
        % Method to allocate complex symbols in a time frequency grid
        function SymbolAllocation = symbol_allocater(varargin)
            if (nargin ~= 1)
                [SubcarrierPerRescourceBlock_, ResourceBlockCount_, ...
                    SymbolsPerResourceElement_, ComplexSymbols_] = varargin{1,2:5};
            else
                SubcarrierPerRescourceBlock_ = varargin{1}.SubcarrierPerRescourceBlock;
                ResourceBlockCount_ = resource_blocks(varargin{:});
                ComplexSymbols_ = symbol_mapper(varargin{:});
                SymbolsPerResourceElement_ = varargin{1}.SymbolsPerResourceElement;
            end
            OfdmSymbolsPerResourceBlock = SubcarrierPerRescourceBlock_*ResourceBlockCount_;
            SymbolAllocation = zeros(SymbolsPerResourceElement_,...
                OfdmSymbolsPerResourceBlock);
            for Index = 1:SymbolsPerResourceElement_
                SymbolAllocation(Index,:) = ComplexSymbols_(1:OfdmSymbolsPerResourceBlock);
                ComplexSymbols_(1:OfdmSymbolsPerResourceBlock) = [];
            end
        end
    end
    
    methods
        % Method which creates a pseudo-random sequence
        % ETSI TS 136 211 V12.3.0(2014-10) with MPN = final sequence
        % length
        function [c_out, x1, x2] = gold_sequencer(varargin)
            if (nargin ~= 1)
                if strcmp(varargin{2},'first_preamble') % *Use Enums in stead of chars*
                    MPN_ = log2(varargin{1})...
                        *varargin{3}.SubcarrierPerRescourceBlock...
                        *resource_blocks(varargin{3})/2;
                elseif strcmp(varargin{2},'second_preamble')
                    MPN_ = log2(varargin{1})...
                        *varargin{3}.SubcarrierPerRescourceBlock...
                        *resource_blocks(varargin{3});
                else
                    MPN_ = varargin{1,2};
                end
            else
                [ResourceBlockCount, ~] = resource_blocks(varargin{:});
                Size_ = ResourceBlockCount...
                    *varargin{1}.SubcarrierPerRescourceBlock;
                MPN_ = log2(varargin{1}.ModulationOrder)*Size_;
            end
            NC  = 1.6e3;
            GoldSequenceLength = 31;
            x1_init = [ones(1,1), zeros(1,GoldSequenceLength-1)];
            x2_init = randi([0,1], 1,GoldSequenceLength);
            c_init  = zeros(1,GoldSequenceLength);
            for i = 1:GoldSequenceLength-1
                c_init(i)  = x2_init(i)*2^i;
            end
            c_init = (de2bi(sum(c_init)));
            x1(1:length(x1_init)) = x1_init;
            x2(1:length(x2_init)) = x2_init;
            c_out = [c_init zeros(1,MPN_-length(c_init))];
            for n = 1: MPN_ + NC
                x1(n+GoldSequenceLength) = mod(x1(n+3) + x1(n),2);
                x2(n+GoldSequenceLength) = mod(x2(n+3) + x2(n+2)+x2(n+1) + x2(n),2);
            end
            for n = 1: MPN_
                c_out(n) = mod(x1(n+NC) + x2(n+NC),2);
            end
        end
    end
    
    methods
        % Method whicht transforms a zero padded matrix with complex
        % symbols in a timesignal
        function IFFT = time_transform(varargin)
            if (nargin ~= 1)
                if strcmp(varargin{1},'preamble')
                    [ResourceBlockCount_, Size_] = resource_blocks(varargin{2});
                    SymbolsPerResourceElement_ = 2;
                    IndexPush = 1;
                else
                    [ResourceBlockCount_, Size_, ...
                        SymbolsPerResourceElement_] = varargin{1,2:4};
                end
            else
                IndexPush = 0;
                [ResourceBlockCount_, Size_] = resource_blocks(varargin{:});
                SymbolsPerResourceElement_ = varargin{1}.SymbolsPerResourceElement;
            end
            VirtualSubcarrierCount = Size_-ResourceBlockCount_...
                *varargin{1+IndexPush}.SubcarrierPerRescourceBlock;
            if strcmp(varargin{1},'preamble')
                SymbolAllocation = preamble_allocater(varargin{2});
            else
                SymbolAllocation = symbol_allocater(varargin{:});
            end
            IFFTFrame = [zeros(SymbolsPerResourceElement_, VirtualSubcarrierCount/2),...
                SymbolAllocation, zeros(SymbolsPerResourceElement_, VirtualSubcarrierCount/2)];
            IFFT = ifft(IFFTFrame, [], 2);
        end
    end
    
    methods
        % Method which creates the first synchronization preamble and sets
        % every second element of the vector to zero
        function PreambleVector = preamble_creator(varargin)
            if (nargin ~= 2)
                [GoldSequence_, ModulationOrder_, Size_] = varargin{1,2:4};
            else
                ModulationOrder_ = 4;
                GoldSequence_ = gold_sequencer(ModulationOrder_ ,varargin{:});
                Size_ = resource_blocks(varargin{2})*varargin{2}.SubcarrierPerRescourceBlock;
            end
            ComplexSymbols = symbol_mapper(ModulationOrder_,...
                GoldSequence_, varargin{:});
            if strcmp(varargin{1},'first_preamble') % *Use Enums to mark entry of cell*
                PreambleVector = zeros(1, Size_);
                for Index  = 2:2:length(PreambleVector)
                    PreambleVector(Index) = ComplexSymbols(1);
                    ComplexSymbols(1) = [];
                end
            else
                PreambleVector = ComplexSymbols;
            end
        end
    end
    
    methods
        function PreambleAllocation = preamble_allocater(varargin)
            if (nargin ~= 1)
                [PreambleVectorOne_, PreambleVectorTwo_] = varargin{1,2,3};
            else
                PreambleVectorOne_ = preamble_creator('first_preamble',varargin{:});
                PreambleVectorTwo_ = preamble_creator('second_preamble',varargin{:});
            end
            PreambleAllocation = [PreambleVectorOne_;PreambleVectorTwo_];
        end
    end
    
    methods
        function TxFrame = frame_creator(varargin)
            if (nargin ~= 1)
                TxFrame = varargin{1,2};
            else
                TimePreamble = time_transform('preamble', varargin{:});
                TimePayload = time_transform(varargin{:});
                TxFrame = [TimePreamble; TimePayload];
            end
        end
    end
    
    methods
        % Method which adds a cyclic extension to each ofdmSymbol
        function TimeSignalCP = cycle_prefixer(varargin)
            if (nargin ~= 1)
                [TimeSignal_, CyclicPrefixLength_]= varargin{1,2:3};
            else
                TimeSignal_ = frame_creator(varargin{:});
                CyclicPrefixLength_ = varargin{1}.CyclicPrefixLength;
            end
            SamplesPerCyclePrefix  = length(TimeSignal_)*CyclicPrefixLength_;
            TimeSignalCP = [TimeSignal_(:,(end-SamplesPerCyclePrefix+1):end), TimeSignal_];
        end
    end
    methods
        function show_goldsequence(varargin)
            [c, x1, x2] = gold_sequencer(varargin{:});
            subplot(2,2,1)
            stem(linspace(0,length(x1),length(x1)),x1),xlim([0 length(x1)]),
            title('First Sequence'),xlabel('samples')
            subplot(2,2,2)
            stem(linspace(0,length(x2),length(x2)),x2),xlim([0 length(x2)]),
            title('Second Sequence'),xlabel('samples')
            subplot(2,2,3)
            stem(linspace(0,length(c),length(c)),c),xlim([0 length(c)]),
            title('GoldSequence'), xlabel('samples')
            subplot(2,2,4)
            stem(linspace(0,2*length(c),2*length(c)-1), abs(2/length(c)*xcorr(c))),
            title('XCorr Goldsequence'), xlim([0 2*length(c)])
        end
    end
    methods
        function show_grid(varargin)
            TxFrame = frame_creator(varargin{:});
            TimeAxis = linspace(0,1/15e3*size(TxFrame,1),size(TxFrame,2));
            SubcarrierCount = linspace(-(size(TxFrame,2)/2),(size(TxFrame,2)/2)-1,size(TxFrame,2));
        end
    end
end