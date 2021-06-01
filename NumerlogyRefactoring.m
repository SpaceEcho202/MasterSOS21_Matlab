classdef NumerlogyRefactoring
    % Numerlogy Class is used to assigne subcarrier to dedicated bandwidth
    % This class will perform all steps to create signal vector and
    % frames
    
    properties
        Bandwidth;                      % Used transmission bandwidth
        ModulationOrder;                % Used for QAM
        Coderate;                       % Used code rate *not implemented*
        FrameCount;                     % How many frames will be uses *not implemented*
        SubcarrierPerRescourceBlock ;   % Smallest assignable unit in grid
        SeedPRBS;                       % Seed to reproduce bit sequence
        SubcarrierSpacing;
        CyclicPrefixLength;
        SymbolsPerResourceElement;
        SlotCount;
        FirstPolynomal;
        SecondPolynomal;
    end
    
    methods
        % Is used as constructor to predifine class variables
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
        % recource elements are used
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
                [ModulationOrder_, BitStream_] = varargin{1,2:3};
            else
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
                [SubcarrierPerRescourceBlock_, ResourceBlocks_, ...
                    SymbolsPerResourceElement_, ComplexSymbols_] = varargin{1,2:5};
            else
                SubcarrierPerRescourceBlock_ = varargin{1}.SubcarrierPerRescourceBlock;
                ResourceBlocks_ = resource_blocks(varargin{:});
                ComplexSymbols_ = symbol_mapper(varargin{:});
                SymbolsPerResourceElement_ = varargin{1}.SymbolsPerResourceElement;
            end
            OfdmSymbolsPerResourceBlock = SubcarrierPerRescourceBlock_*ResourceBlocks_;
            SymbolAllocation = zeros(SymbolsPerResourceElement_,...
                OfdmSymbolsPerResourceBlock);
            for Index = 1:SymbolsPerResourceElement_
                SymbolAllocation(Index,:) = ComplexSymbols_(1:OfdmSymbolsPerResourceBlock);
                ComplexSymbols_(1:OfdmSymbolsPerResourceBlock) = [];
            end
        end
    end
    methods
        % Method which creates a Pseudo-random sequence *ETSI TS 136 211 V12.3.0(2014-10)*
        function [c_out, x1, x2, MPN, Pream] = gold_sequencer(varargin)
            if (nargin ~= 1)
               MPN_ = varargin{1,2};
            else
               MPN_ = log2(varargin{1}.ModulationOrder)...
                   *resource_blocks(varargin{:}); 
            end
            NC  = 1.6e3;
            GoldSequenceLength = 31;
            x1_init = [ones(1,1), zeros(1,GoldSequenceLength-1)];
            x2_init = randi([0,1], 1,GoldSequenceLength);    
            c_init  = zeros(1,GoldSequenceLength);
            c_temp  = zeros(1,GoldSequenceLength);
            for i = 1:GoldSequenceLength
                c_temp(i)  = x2_init(i)*2^i;
            end
            c_temp = char(dec2bin(sum(c_temp)));
            for i = 1:GoldSequenceLength 
                if c_temp(i) ==  '1'
                    c_init(i) = 1;
                else
                    c_init(i) = 0;
                end
            end          
            x1(1:length(x1_init)) = x1_init;
            x2(1:length(x2_init)) = x2_init;
            c = c_init;
            for n = 1: MPN + NC
                x1(n+GoldSequenceLength) = mod(x1(n+3) + x1(n),2);
                x2(n+GoldSequenceLength) = mod(x2(n+3) + x2(n+2)+x2(n+1) + x2(n),2);
            end           
            for n = 1: MPN
                c(n) = mod(x1(n+NC) + x2(n+NC),2);
            end   
            c_out = c;
            for Index = 1: MPN/ 2
                DecStream(Index,:) = bin2dec(num2str(c(1:2)));
                c(1:2) = [];
            end
            Pream = qammod(DecStream',4,'gray');
        end     
    end
    methods
        % Method whicht transforms a matrix with complex symbols in a
        % timesignal
        function IFFT = time_transform(varargin)
            if (nargin ~= 1)
                [ResourceBlocks_, Size_, ...
                    SymbolsPerResourceElement_] = varargin{1,2:4};
            else
                [ResourceBlocks_, Size_] = resource_blocks(varargin{:});
                SymbolsPerResourceElement_ = varargin{1}.SymbolsPerResourceElement; 
            end
            VirtualSubcarrierCount = Size_-ResourceBlocks_...
                *varargin{1}.SubcarrierPerRescourceBlock;
            SymbolAllocation = symbol_allocater(varargin{:});
            IFFTFrame = [zeros(SymbolsPerResourceElement_, VirtualSubcarrierCount/2),...
                SymbolAllocation, zeros(SymbolsPerResourceElement_, VirtualSubcarrierCount/2)];
            IFFT = ifft(IFFTFrame, [], 2);
        end
    end
    
    methods 
        % Method which adds a cyclic extension to each ofdmSymbol
        function TimeSignalCP = cycle_prefixer(varargin)
            if (nargin ~= 1)
                [TimeSignal_, CyclicPrefixLength_]= varargin{1,2:3}; 
            else
                TimeSignal_ = time_transform(varargin{:});
                CyclicPrefixLength_ = varargin{1}.CyclicPrefixLength;
            end
            SamplesPerCyclePrefix  = length(TimeSignal_)*CyclicPrefixLength_;
            TimeSignalCP = [TimeSignal_(:,(end-SamplesPerCyclePrefix+1):end), TimeSignal_];
        end
    end
end