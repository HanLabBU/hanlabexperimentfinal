function testwrite2(fname,data)

fid = fopen(fname,'a');
fwrite(fid,data,'uint16');
fclose(fid);