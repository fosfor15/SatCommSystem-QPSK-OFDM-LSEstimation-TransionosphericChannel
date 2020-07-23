function [BER, numBits] = BERTool_QPSK_OFDM_RicianChannel_LSEstimation(EbNo, maxNumErrs, maxNumBits)

    persistent FullOperatingTime

    % Display Line on the Start of Imitation Modeling
    disp('======================================');
    % Start Time
    tStart = clock;
    % Total Duration of Imitation Modeling
    % Saving for each trials. To restart need 'clear all' command.
    if isempty(FullOperatingTime)
        FullOperatingTime = 0;
    end
    
    
    %%%%% Initial Information Source %%%%%
    
    % Symbol Rate
    Rs = 100e3;
    % Symbol Duration
    Ts = 1/Rs;
    
    
    %%%%% QPSK Modulation %%%%%
    
    % Number of Bits in QPSK Symbol by definition
    k = 2;
    
    % QPSK Modulator Object
    QPSKModulator = comm.QPSKModulator( ...
        'PhaseOffset', pi/4, ...
        'BitInput', true, ...
        'SymbolMapping', 'Gray' ...
    );

    % QPSK Demodulator Object
    QPSKDemodulator = comm.QPSKDemodulator( ...
        'PhaseOffset', QPSKModulator.PhaseOffset, ...
        'BitOutput', QPSKModulator.BitInput, ...
        'SymbolMapping', QPSKModulator.SymbolMapping, ...
        'DecisionMethod', 'Hard decision' ...
    );


    %%%%% OFDM Modulation %%%%%
    
    % Number of Subcarriers (equal to Number of FFT points)
    numSC = 256;
    
    % Guard Bands Subcarriers
    GuardBandSC = [10; 10];
    
    % Central Null Subcarrier
    DCNull = true;
    DCNullSC = numSC/2 + 1;
    
    % Number of Pilot Subcarriers
    numPilotSC = 10;
    % Location of Pilot Subcarriers
    PilotSC = round(linspace(GuardBandSC(1) + 5, numSC - GuardBandSC(2) - 6, numPilotSC))';
    
    % Length of Cyclic Prefix
    lenCP = numSC/4;
    
    
    % OFDM Modulator Object
    OFDMModulator = comm.OFDMModulator( ...
        'FFTLength', numSC, ...
        'NumGuardBandCarriers', GuardBandSC, ...
        'InsertDCNull', DCNull, ...
        'PilotInputPort', true, ...
        'PilotCarrierIndices', PilotSC, ...
        'CyclicPrefixLength', lenCP ...
    );

    % OFDM Demodulator Object
    OFDMDemodulator = comm.OFDMDemodulator(OFDMModulator);
    

    % Number of Data Subcarriers
    numDataSC = info(OFDMModulator).DataInputSize(1);
    % Size of Data Frame
    szDataFrame = [k*numDataSC 1];
    
    % Size of Pilot Frame
    szPilotFrame = info(OFDMModulator).PilotInputSize;


    %%%%% Transionospheric Communication Channel %%%%%
    
   % Discrete Paths Relative Delays
    PathDelays = [0 Ts/5];
    % Discrete Paths Average Gains
    PathAvGains = [0 -10];
    % Discrete Paths K Factors
    K = [3 3];
    % Max Doppler Frequency Shift
    fD = 25;
    
    % Rician Channel Object
    RicianChannel = comm.RicianChannel( ...
        'SampleRate', Rs, ...
        'PathDelays', PathDelays, ...
        'AveragePathGains', PathAvGains, ...
        'NormalizePathGains', true, ...
        'KFactor', K, ...
        'MaximumDopplerShift', fD, ...
        'DirectPathDopplerShift', zeros(size(K)), ...
        'DirectPathInitialPhase', zeros(size(K)), ...
        'DopplerSpectrum', doppler('Jakes') ...
    );

    % Delay in Rician Channel Object
    ChanDelay = info(RicianChannel).ChannelFilterDelay;    

    % AWGN Channel Object
    AWGNChannel = comm.AWGNChannel( ...
        'NoiseMethod', 'Signal to noise ratio (SNR)', ...
        'SNR', EbNo + 10*log10(k) + 10*log10(numDataSC/numSC) ...       
    );

    
    %%%%% Imitation Modeling %%%%%
    
    % Import Java class for BERTool
    import com.mathworks.toolbox.comm.BERTool;    
    
    % BER Calculator Object
    BERCalculater = comm.ErrorRate;
    % BER Intermediate Variable
    BERIm = zeros(3,1);
    
    
    % Imitation Modeling Loop
    tLoop1 = clock;
    while BERIm(2) < maxNumErrs && BERIm(3) < maxNumBits
        
        % Check of User push Stop
        if BERTool.getSimulationStop
            break;
        end
        
        
        % >>> Transmitter >>>
        
        % Generation of Data Bits
        BitsTx = randi([0 1], szDataFrame);
        
        % QPSK Modulation
        SignalTx1 = QPSKModulator(BitsTx);
        
        % Generation of Pilot Signals
        PilotSignalTx = complex(ones(szPilotFrame), zeros(szPilotFrame));
        % OFDM Modulation
        SignalTx2 = OFDMModulator(SignalTx1, PilotSignalTx);
        
        % Power of Transmitted Signal
        SignalTxPower = var(SignalTx2);
        
        
        % >>> Transionospheric Communication Channel >>>
        
        % Adding zero samples to the end of Transmitted Signal
        % to not lose shifted samples caused by delay after Rician Channel
        SignalTx2 = [SignalTx2; zeros(ChanDelay, 1)];
        % Rician Channel
        SignalChan1 = RicianChannel(SignalTx2);
        % Removing first ChanDelay samples and
        % selection of Channel's Signal related to Transmitted Signal
        SignalChan1 = SignalChan1(ChanDelay + 1 : end);
        
        % AWGN Channel
        AWGNChannel.SignalPower = SignalTxPower;
        SignalChan2 = AWGNChannel(SignalChan1);
        
        
        % >>> Receiver >>>
        
        % OFDM Demodulation
        [SignalRx1, PilotSignalRx] = OFDMDemodulator(SignalChan2);
    
        % LS Channel Estimation
        % Channel Frequency Response
        ChanFR_dp = PilotSignalRx ./ PilotSignalTx;
        ChanFR_int = interp1( ...
            PilotSC, ...
            ChanFR_dp, ...
            GuardBandSC(1) + 1 : numSC - GuardBandSC(2), ...
            'pchip' ...
        );
        ChanFR_int([PilotSC; DCNullSC] - GuardBandSC(1)) = [];
        % LS Solution
        SignalRx2 = SignalRx1 ./ ChanFR_int.';
        
        % QPSK Demodulation
        BitsRx = QPSKDemodulator(SignalRx2);
        
        % BER Calculation
        BERIm = BERCalculater(BitsTx, BitsRx);
        
    end
    tLoop2 = clock;    
    
    % BER Results
    BER = BERIm(1);
    numBits = BERIm(3);
    disp(['BER = ', num2str(BERIm(1), '%.5g'), ' at Eb/No = ', num2str(EbNo), ' dB']);
    disp(['Number of bits = ', num2str(BERIm(3))]);
    disp(['Number of errors = ', num2str(BERIm(2))]);
    
    
    % Performance of Imitation Modeling
    Perfomance = BERIm(3) / etime(tLoop2, tLoop1);
    disp(['Perfomance = ', num2str(Perfomance), ' bit/sec']);    
    
    % Duration of this Imitation Modeling
    duration = etime(clock, tStart);
    disp(['Operating time = ', num2str(duration), ' sec']);
    
    % Total Duration of Imitation Modeling
    FullOperatingTime = FullOperatingTime + duration;
    assignin('base', 'FullOperatingTime', FullOperatingTime);

end