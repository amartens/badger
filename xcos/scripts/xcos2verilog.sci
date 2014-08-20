//function converting an xcos model using badger library blocks to verilog

function [result] = xcos2verilog(palette, filename)
  result = -1;

  //TODO back up current file if exists

  //create or clear file for writing
  [fd, err] = mopen(filename, 'w')

  //TODO error checking
  
  

  //close file
  mclose(fd);

  result = 0;
endfunction
