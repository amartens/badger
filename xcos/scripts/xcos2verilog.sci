//this file is part of ratel.
//
//    ratel is free software: you can redistribute it and/or modify
//    it under the terms of the gnu general public license as published by
//    the free software foundation, either version 3 of the license, or
//    (at your option) any later version.
//
//    ratel is distributed in the hope that it will be useful,
//    but without any warranty; without even the implied warranty of
//    merchantability or fitness for a particular purpose.  see the
//    gnu general public license for more details.
//
//    you should have received a copy of the gnu general public license
//    along with ratel.  if not, see <http://www.gnu.org/licenses/>.

function [ok] = xcos2verilog(target)
//convert an xcos model using ratel library blocks to verilog
//target is an xcos model file to be converted

  ok = %f;
  fname = 'xcos2verilog'; //for logging

  //TODO error checking
  //TODO back up current design

  //open model (handle in scs_m after import)
  ratel_log(msprintf('importing %s', target)+'\n' , [fname]);
  ko = importXcosDiagram(target);
  if ko == %f | ~isdef('scs_m') then
    ratel_log(msprintf('Error importing %s', target)+'\n', [fname, 'error']);
    return;
  end //if

  dtitle = scs_m.props.title;

  //preprocess diagram to aid in HDL generation
  ratel_log(msprintf('preprocessing diagram %s', dtitle)+'\n', [fname]);
  [preprocessed_scs_m, ko] = preprocess_diagram(scs_m);
  if ~ko,
    msg = msprintf('error preprocessing diagram %s', dtitle);
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end  

  //adjust (mostly) port info 
  ratel_log(msprintf('adjusting diagram %s', dtitle)+'\n', [fname]);
  [adjusted_scs_m, ko] = adjust_diagram(preprocessed_scs_m);
  if ~ko,
    msg = msprintf('error adjusting diagram %s', dtitle);
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end  

  //generate files and directories based on diagram 
  ratel_log(msprintf('generating HDL for diagram %s', dtitle)+'\n', [fname]);
  ko = diagram2verilog(adjusted_scs_m, []);
  if ~ko,
    msg = msprintf('error generating HDL for diagram %s', dtitle);
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end  

  ok = %t;
endfunction //xcos2verilog
