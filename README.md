# Satellite Communication System using QPSK and OFDM with LS Estimation in Transionospheric Communication Channel with Multipath and Limited Coherence Bandwidth [![View SCS with QPSK-OFDM LSEstimation in Transionospheric Channel on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/78547-scs-with-qpsk-ofdm-lsestimation-in-transionospheric-channel)

### Brief description

This repo is dedicated to MATLAB Imitation Modeling and provides BER of Satellite Communication System (SCS) using QPSK and OFDM Modulation in Rician Transionospheric Communication Channel with Multipath Propagation and Limited Coherence Bandwidth, that causes Frequency-Selective Fading and Intersymbol Interference of received signal.

For reducing signal impairments and for BER improvement SCS uses OFDM technique with Cyclic Prefix and Least Squares (LS) Channel Estimation, that determines Channel Frequency Response based on observing for Pilot Signals known a priori in the receiver.

Files in the repo will be useful for any communication engineer and MATLAB programmer, who is looking for examples of the BER Imitation Modeling of the Comm Systems.

## Content of the repo

The [SatCommSystem_LSModeling.mlx](SatCommSystem_LSModeling.mlx) is a Live Script and contains detailed code, explanations, analysis and references, and performs Imitation Modeling in Live Script Editor.

The [BERTool_QPSK_RicianChannel.m](BERTool_QPSK_RicianChannel.m) and [BERTool_QPSK_OFDM_RicianChannel_LSEstimation.m](BERTool_QPSK_OFDM_RicianChannel_LSEstimation.m) are functions that can be used in [BER Analyzer Tool](https://www.mathworks.com/help/comm/ug/bit-error-rate-ber.html#bsvziy0).

For BER and efficiency research presented files perform Imitation Modeling for the next cases:
* arbitrary parameters of Transionospheric Communication Channel and signal impairments:
  * [Rician Fading](https://www.mathworks.com/help/comm/ref/comm.ricianchannel-system-object.html);
  * [Rayleigh Fading](https://www.mathworks.com/help/comm/ref/comm.rayleighchannel-system-object.html);
  * [Multipath Fading](https://www.mathworks.com/help/comm/examples/multipath-fading-channel.html);
  * [Frequency-Selective Fading](https://www.mathworks.com/help/comm/examples/multipath-fading-channel.html#d120e15459);
  * Intersymbol Interference;
* two types of SCS Transmitter-Receiver Scheme:
  * only using QPSK;
  * using QPSK and OFDM;
* wide range of [OFDM parameters](https://www.mathworks.com/help/comm/ref/comm.ofdmmodulator-system-object.html):
  * number and structure of Subcarriers in Time-Frequency Domain;
  * number and location of Pilot Subcarriers;
* arbitrary Ratio of Channel Coherence vs. Signal Bandwidth;
* modulation type and order, initial symbol rate, etc.;
* signal analysis and visualization.

## BER Results

Here are some BER Results of Imitation Modeling presented in the next Graphs.

The Satellite Communication System uses initial QPSK symbol rate of 100.000 baud and performs transmittion over Transionospheric Channel with different Ratio of Channel Coherence / Signal Bandwidth, that showed in the title of each Graph.

For reducing signal impairments and for BER improvement SCS uses OFDM Modulation with 256 Subcarriers, 20 Guard Bands, Cyclic Prefix 1/4 of OFDM symbol duration and LS Channel Estimation with 10 uniformly distributed Pilot Subcarriers.

![BER of SCS with QPSK OFDM, Ratio Channel Coherence / Signal Bandwidth = 5/1](/BERGraphs/BER_CoherenceSignalBandwidth_5-1.png)
![BER of SCS with QPSK OFDM, Ratio Channel Coherence / Signal Bandwidth = 2/1](/BERGraphs/BER_CoherenceSignalBandwidth_2-1.png)
![BER of SCS with QPSK OFDM, Ratio Channel Coherence / Signal Bandwidth = 1/1](/BERGraphs/BER_CoherenceSignalBandwidth_1-1.png)

As we see, using of OFDM and QPSK, compared to using only QPSK, demonstrates BER improvement in Transionospheric Communication Channel under Multipath Propagation and Limited Coherence Bandwidth.
