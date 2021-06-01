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
        ComplexSymbols;                 % 
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
        function BitStream = bit_stream(varargin)
            if (nargin ~= 1)
                [BitStreamLength_, SeedPRBS_] = varargin{1,2:3};
            else
                SeedPRBS_ = varargin{1}.SeedPRBS;
                BitStreamLength_ = log2(varargin{1}.ModulationOrder)...
                *varargin{1}.SubcarrierPerRescourceBlock...
                *resource_blocks(obj)*varargin{1}.SymbolsPerResourceElement;
            end
            BitStream = nrPRBS(SeedPRBS_, BitStreamLength_)';
        end
    end
    methods
        % Method to encode a parsed logical bitstream into graycoded symbols
        % depending on parsed modulation order
        function ComplexSymbolFrame = symbol_mapper(varargin)
            if (nargin ~= 1)
               [ModulationOrder_, BitStream_] = varargin{1,2:3};
            else
                ModulationOrder_ = varargin{1}.ModulationOrder;
                BitStream_ = bit_stream()/log2(ModulationOrder_);
            end
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
end