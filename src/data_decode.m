function [ rx_information,info_error ] = data_decode( rx_bitstream, start_location )
%DATA_DECODE Performs CRC checking of rx_bistream
%   INPUT arguments:        received and demodulated bitstream
%
%   OUTPUT arguments:       information words and errors
%
%   Author:                 Joshua Peter Ebenezer
%   Date of creation:       December 11th, 2017
%

synchronized = rx_bitstream(start_location:end);

% number of messages
no_msgs = floor(length(synchronized)/104);

rx_information = zeros(1,no_msgs*4*16);

info_error = zeros(1,no_msgs*4);

blk1_msg = zeros(1,no_msgs*26);
blk2_msg = zeros(1,no_msgs*26);
blk3_msg = zeros(1,no_msgs*26);
blk4_msg = zeros(1,no_msgs*26);

for j=1:no_msgs
    % each group is of length 104 bits
    grp = synchronized((j-1)*104+1:j*104);
    % separate the blocks in each group
    blk1_msg((j-1)*26+1:j*26) = grp(1:26);
    blk2_msg((j-1)*26+1:j*26) = grp(27:52);
    blk3_msg((j-1)*26+1:j*26) = grp(53:78);
    blk4_msg((j-1)*26+1:j*26) = grp(79:104);
end

err3 = zeros(1,no_msgs);

% calculate CRC for each block and generate the blocks
offsetA = [0 0 1 1 1 1 1 1 0 0];
H1 = comm.CRCDetector([10 8 7 5 4 3 0],'FinalXOR',offsetA,'ChecksumsPerFrame',no_msgs);
[blk1_info, err1] = step(H1,blk1_msg.');
blk1_info = blk1_info.';

offsetB = [0 1 1 0 0 1 1 0 0 0];
H2 = comm.CRCDetector([10 8 7 5 4 3 0],'FinalXOR',offsetB,'ChecksumsPerFrame',no_msgs);
[blk2_info, err2] = step(H2,blk2_msg.');
blk2_info = blk2_info.';

for j=1:no_msgs    
    [~, version] = syndrome(blk3_msg((j-1)*26+1:j*26));
    
    if ( version == 'A')
        offsetC = [0 1 0 1 1 0 1 0 0 0];
        H3 = comm.CRCDetector([10 8 7 5 4 3 0],'FinalXOR',offsetC);
        [blk3_info((j-1)*16+1:j*16), err3(j)] = step(H3,blk3_msg((j-1)*26+1:j*26).');        
    else
        offsetC2 = [1 1 0 1 0 1 0 0 0 0];
        H3 = comm.CRCDetector([10 8 7 5 4 3 0],'FinalXOR',offsetC2);
        [blk3_info((j-1)*16+1:j*16), err3(j)] = step(H3,blk3_msg((j-1)*26+1:j*26).');
    end
end


offsetD = [0 1 1 0 1 1 0 1 0 0];
H4 = comm.CRCDetector([10 8 7 5 4 3 0],'FinalXOR',offsetD,'ChecksumsPerFrame',no_msgs);
[blk4_info, err4] = step(H4,blk4_msg.');
blk4_info = blk4_info.';

% concatenate the information and error vectors separately
for j=1:no_msgs
    rx_information((j-1)*64+1:j*64) = cat(2,blk1_info((j-1)*16+1:j*16),blk2_info((j-1)*16+1:j*16),blk3_info((j-1)*16+1:j*16),blk4_info((j-1)*16+1:j*16));
    info_error((j-1)*4+1:j*4) = cat(2,err1(j),err2(j),err3(j),err4(j));
end

end