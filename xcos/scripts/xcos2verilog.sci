function [ok] = xcos2verilog(target)
//convert an xcos model using ratel library blocks to verilog
//target is an xcos model to be converted

  ok = %f;
  fname = 'xcos2verilog'; //for logging

  //TODO error checking
  //TODO back up current design

  //open model (handle in scs_m after load)
  ratel_log(msprintf('importing %s', target)+'\n' , [fname]);
  ko = importXcosDiagram(target);
  if ko == %f | ~isdef('scs_m') then
    ratel_log(msprintf('Error importing %s', target)+'\n', [fname, 'error']);
    return;
  end //if

  //adjust (mostly) port info 
  ratel_log(msprintf('adjusting diagram %s',scs_m.props.title)+'\n', [fname]);
  [ko, adjusted_scs_m] = adjust_diagram(scs_m);
  if ~ko,
    msg = msprintf('error updating diagram %s', scs_m.props.title);
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end  

  //generate files and directories based on diagram 
  ratel_log(msprintf('generating hdl for diagram %s', scs_m.props.title)+'\n', [fname]);
  ko = diagram2verilog(adjusted_scs_m, connectmat, []);

  ok = %t;
endfunction //xcos2verilog
