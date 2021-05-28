classdef Numerlogy
    % Numerlogy Class is used to assigne subcarrier to dedicated bandwidth
    % This class will perform all steps to create signal vector and
    % frames
    
    properties
        Bandwidth;                      %Used transmission bandwidth
        ModulationOrder;                %Used for QAM
        Coderate;                       %Used code rate *not implemented*
        FrameCount;                     %How many frames will be uses *not implemented*
        SubcarrierPerRescourceBlock ;   %Smallest assignable unit in grid
        SeedPRBS;                       %Seed to reproduce bit sequence
        ComplexSymbols;
        SubcarrierSpacing;
        CyclicPrefixLength;
        SymbolsPerResourceElement;   
        SlotCount;
        FirstPolynomal;
        SecondPolynomal;
    end
    methods
        % Is used as constructor to predifine class variables
        function obj                                = Numerlogy()
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
        function [ResourceBlockCount, FFTSize] = resource_blocks(obj)
            switch obj.Bandwidth
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
        function BitStream = bit_stream(obj)
            BitPerSymbol = log2(obj.ModulationOrder);
            BitStreamLength = BitPerSymbol*obj.SubcarrierPerRescourceBlock...
                *resource_blocks(obj)*obj.SymbolsPerResourceElement;
            BitStream = nrPRBS(obj.SeedPRBS, BitStreamLength)';
        end
    end
    methods
        % Method to encode a parsed logical bitstream into graycoded symbols
        % depending on parsed modulation order
        function ComplexSymbolFrame = symbol_mapper(obj)
            BitPerSymbol = log2(obj.ModulationOrder);
            SymbolsInBitStream = length(bit_stream(obj))/BitPerSymbol;
            BitStream = bit_stream(obj);
            DecStream = zeros(SymbolsInBitStream , 1);
            for Index = 1:SymbolsInBitStream
                DecStream(Index,:) = bin2dec(num2str(BitStream(1:BitPerSymbol)));
                BitStream(1:BitPerSymbol) = [];
            end
            OfdmSymbolsPerResourceBlock = obj.SubcarrierPerRescourceBlock*resource_blocks(obj);
            obj.ComplexSymbols = qammod(DecStream', obj.ModulationOrder ,'gray');
            ComplexSymbolFrame = zeros(obj.SymbolsPerResourceElement, OfdmSymbolsPerResourceBlock);
            for Index = 1:obj.SymbolsPerResourceElement
                ComplexSymbolFrame(Index,:) = obj.ComplexSymbols(1:OfdmSymbolsPerResourceBlock);
                obj.ComplexSymbols(1:OfdmSymbolsPerResourceBlock) = [];
            end
        end
    end
    methods
        % Methods which transforms a zero padded vector in a time
        % vector
        function TimeSignal = ofdm_time_signal(obj)
            [ResourceBlocks, Size] = resource_blocks(obj);
            VirtualSubcarrierCount = Size-ResourceBlocks*obj.SubcarrierPerRescourceBlock;
            ComplexSymbolFrame = symbol_mapper(obj);
            IFFTFrame = [zeros(obj.SymbolsPerResourceElement, VirtualSubcarrierCount/2),...
                ComplexSymbolFrame, zeros(obj.SymbolsPerResourceElement, VirtualSubcarrierCount/2)];
            TimeSignal = ifft(IFFTFrame, [], 2);
        end
    end
    methods 
        % Method which adds a cyclic extension to each ofdmSymbol
        function TimeSignalCP = cycle_prefixer(obj)
            TimeSignal = ofdm_time_signal(obj);
            SamplesPerCyclePrefix  = length(TimeSignal)*obj.CyclicPrefixLength;
            TimeSignalCP = [TimeSignal(:,(end-SamplesPerCyclePrefix+1):end), TimeSignal];
        end
    end
    methods
        function GoldSequence = gold_sequencer(obj)
            SequenceLength = log2(obj.ModulationOrder)*resource_blocks(obj);
      
            SmallestPolynomal = ceil(log2(SequenceLength/2)-1);
            
            x1_init = [0 0 1 0 0 0];
            x2_init = [0 0 0 0 1 0];
            
            x1 = zeros(1,SequenceLength);
            x2 = zeros(1,SequenceLength);
            
            x1(1:SmallestPolynomal+1) = x1_init;
            x2(1:SmallestPolynomal+1) = x2_init;
            
            for n = 1: SequenceLength
                x1(n) = mod(x1(n+3) + x1(n),2);
            end
            
            GoldSequence = zeros(1,SequenceLength);
                     
        end
    end
    %methods
    %    function Preamble = preamble_creator(obj)
    %        
    %    end
    %end
end

