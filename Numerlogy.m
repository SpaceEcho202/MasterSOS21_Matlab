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
        % Method which creates a Pseudo-random sequence *ETSI TS 136 211 V12.3.0(2014-10)*
        function [c_out, x1, x2, MPN, Pream ] = gold_sequencer(obj)
               
            NC  = 1.6e3;
            GoldSequenceLength = 31;
            MPN = log2(obj.ModulationOrder)*resource_blocks(obj);          
            
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
            for Index = 1:MPN/ 2
                DecStream(Index,:) = bin2dec(num2str(c(1:2)));
                c(1:2) = [];
            end
            Pream = qammod(DecStream',4,'gray');
        end     
    end
    %methods
    %    function Preamble = preamble_creator(obj)
    %        
    %    end
    %end
end

