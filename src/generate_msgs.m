function [ rds_bitstream, information ] = generate_msgs( no_msgs,read_from_file,rds_stream_length,version )
%GENERATE_MSGS returns the RDS bit stream corresponding to a message signal
%   INPUT arguments:        number of messages, option to read
%                           message from file or to generate pseudo data,
%                           length of bitstream allowed, rds version (A or
%                           B)
%
%   OUTPUT arguments:       information words and checkwords concatenated,
%                           and information words separately
%
%   Author:                 Joshua Peter Ebenezer
%   Date of creation:       December 11th, 2017
%
%%

if (read_from_file == 1)
    rds_bitstream = load('rds_data.mat');
else
    % initialize bitstream
    rds_bitstream = zeros(1,rds_stream_length);
    
    msg_length = no_msgs*16*4;
    % generate random binary data
    binary_data = randi([0 1], 1,msg_length);
    
    information = zeros(1,msg_length);
    
    % generate data for each block separately
    blk1_info =  binary_data(1:msg_length/4);
    blk2_info = binary_data(msg_length/4 + 1:msg_length/2);
    blk3_info = binary_data(msg_length/2 + 1:3*msg_length/4);
    blk4_info = binary_data(3*msg_length/4 + 1:msg_length);
    
    % calculate CRC for each block and generate the blocks
    offsetA = [0 0 1 1 1 1 1 1 0 0];
    H1 = comm.CRCGenerator([10 8 7 5 4 3 0],'FinalXOR',offsetA,'ChecksumsPerFrame',no_msgs);
    blk1_msg = H1(blk1_info.');
    blk1_msg = blk1_msg.';
    
    offsetB = [0 1 1 0 0 1 1 0 0 0];
    H2 = comm.CRCGenerator([10 8 7 5 4 3 0],'FinalXOR',offsetB,'ChecksumsPerFrame',no_msgs);
    blk2_msg = H2(blk2_info.');
    blk2_msg = blk2_msg.';
    
    if (version == 'A')
        offsetC = [0 1 0 1 1 0 1 0 0 0];
        H3 = comm.CRCGenerator([10 8 7 5 4 3 0],'FinalXOR',offsetC,'ChecksumsPerFrame',no_msgs);
        blk3_msg = H3(blk3_info.');
        blk3_msg = blk3_msg.';
    else
        offsetC2 = [1 1 0 1 0 1 0 0 0 0];
        H3 = comm.CRCGenerator([10 8 7 5 4 3 0],'FinalXOR',offsetC2,'ChecksumsPerFrame',no_msgs);
        blk3_msg = H3(blk3_info.');
        blk3_msg = blk3_msg.';
    end
    
    offsetD = [0 1 1 0 1 1 0 1 0 0];
    H4 = comm.CRCGenerator([10 8 7 5 4 3 0],'FinalXOR',offsetD,'ChecksumsPerFrame',no_msgs);
    blk4_msg = H4(blk4_info.');
    blk4_msg = blk4_msg.';
    
    % concatenate the information and error blocks
    for j=1:no_msgs
        rds_bitstream((j-1)*104+1:j*104) = cat(2,blk1_msg((j-1)*26+1:j*26),blk2_msg((j-1)*26+1:j*26),blk3_msg((j-1)*26+1:j*26),blk4_msg((j-1)*26+1:j*26));
        information((j-1)*64+1:j*64) = cat(2,blk1_info((j-1)*16+1:j*16),blk2_info((j-1)*16+1:j*16),blk3_info((j-1)*16+1:j*16),blk4_info((j-1)*16+1:j*16));
    end
    
end
end

