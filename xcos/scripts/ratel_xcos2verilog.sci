function [result] = ratel_xcos2verilog(model_path, filename)
//function converting an xcos model using ratel library blocks to verilog
  result = %F;
  //for logging
  fname = 'ratel_xcos2verilog';

  //TODO back up current file if exists

  //create or clear file for writing
  [fd, err] = mopen(filename, 'w');

  //TODO error checking
  
  //open model (handle in scs_m after load)
  result = importXcosDiagram(model_path);
  if or([result == %F, isdef('scs_m') == %F]) then
    msg = msprintf('Error importing %s\n', model_path);
    ratel_log(msg, [fname, 'error']);
    return;
  end //if

  //we run c_pass1 to do certain connectivity checks and 'flatten' structure
  [blklst, connectmat, ccmat, cor, corinv, ok]=c_pass1(scs_m);  
  if ~ok then
    ratel_log('error in first pass\n', [fname, 'error']);
    return;
  end
 
  //adjust size of vector passed through ports 
  ratel_log('adjusting inout\n', [fname, 'trace']);
  [ok,blklst]=ratel_adjust_inout(blklst,connectmat)
  if ~ok then
    ratel_log('error adjusting port inout\n', [fname, 'error']);
    return;
  end
  
  //adjust type of input/output ports
  ratel_log('adjusting type\n', [fname, 'trace']);
  [ok, blklst]=ratel_adjust_typ(blklst, connectmat)
  
  if ~ok then
    ratel_log('error adjusting port type\n', [fname, 'error']);
    return;
  end

  //adjust fixed point info for blocks
  ratel_log('adjusting fixed point info\n', [fname, 'trace']);
  [ok, blklst] = ratel_adjust_fp(blklst, connectmat)

  if ~ok then
    ratel_log('error adjusting fixed point info\n', [fname, 'error']);
    return;
  end

  //now go through all objects in original design
  //we use this instead of the flattened design as we
  //need to preserve hierachy
  //also, the block identity is not available from the model structure
  //but is from the gui variable on the object
  //(perhaps we could use the model's sim parameter?)

  objects = scs_m.objs;

  //sort into ports, links and blocks
  [ok, ports, blocks, links] = ratel_sort_objects(objects);
  if ~ok then
    ratel_log('error sorting objects\n', [fname, 'error']);
    return;
  end //if

  //verilog intro
  //TODO MS uses '\'
  name_tokens = tokens(model_path, ['/']);  
  file_name = tokens(name_tokens($), ['.']);  //take last item of path
  module_name = file_name(1);                 //take first item before '.'
  [result] = ratel_verilog_intro(fd, module_name, ports);

  //create ports
  [ok] = ratel_ports2verilog(fd, ports);
  if ~ok then
    ratel_log('error translating ports\n', [fname, 'error']);
    return;
  end //if
  mfprintf(fd, '\n');

  //create links
  [ok] = ratel_links2verilog(fd, links, objects);
  if ~ok then
    ratel_log('error translating links\n', [fname, 'error']);
    return;
  end //if

  //create blocks
  [ok] = ratel_blocks2verilog(fd, blocks, links); 
  if ~ok then
    ratel_log('error translating blocks\n', [fname, 'error']);
    return;
  end //if

  //verilog epilogue
  [ok] = ratel_verilog_epilogue(fd, module_name);
  if ~ok then
    ratel_log('error writing epilogue\n', [fname, 'error']);
    return;
  end //if

  //close file
  mclose(fd);

  result = %T;
endfunction //ratel_xcos2verilog

function[ok] = ratel_verilog_epilogue(fd, module_name)
  ok = %F;
  mfprintf(fd, 'endmodule //%s\n', module_name);
  ok = %T;
endfunction //verilog_epilogue 

function[ok] = ratel_blocks2verilog(fd, blocks, links)
  //TODO
  ok = %T;
endfunction //ratel_blocks2verilog

function[ok] = ratel_links2verilog(fd, links, objects)
//convert xcos links to verilog wires
  ok = %F;
  fname = 'ratel_links2verilog';
  for link_index = 1:length(links),
    lnk = links(link_index);
    
    from_index = lnk.from(1);
    from_port = lnk.from(2);
    from_type = lnk.from(3); 

    to_index = lnk.to(1);
    to_port = lnk.to(2);
    to_type = lnk.to(3); 

    //we use the block with the output port as the name
    if from_type == 0 then
      source_index = from_index;
      source_port = from_port;
    else
      source_index = to_index;
      source_port = to_port;
    end //if

    if source_index > length(objects) then
      msprintf('source index (%d) for link (%d) exceeds number of blocks (%d)', source_index, link_index, length(objects));
      ratel_log(msg, [fname, 'error']);
      return;
    end

    source_block = objects(source_index);
    //TODO not enough to check for valid ratel block
    if strcmp(typeof(source_block), 'Block') ~= 0,
      ratel_log('not a valid ratel block', [fname, 'error']);
    end
    graphics = source_block.graphics;
    label = graphics.exprs(1);

    //we use the port index to uniquely identify the port
    link_name = msprintf('%s%d', label, source_port);

    //TODO width calculation

    mfprintf(fd, '\twire %s;\n', link_name);
    
  end //for
  ok = %T;
endfunction //ratel_links2verilog

function[ok] = ratel_ports2verilog(fd, ports)
//convert inport and outports to verilog
  ok = %F;
  fname = 'ratel_ports2verilog';
  for port_index = 1:length(ports),
    port = ports(port_index);
    block_type = port.gui;
    if (strcmp(block_type, "inport") == 0) then 
      mfprintf(fd, '\tinput');
    elseif (strcmp(block_type, "outport") == 0) then 
      mfprintf(fd, '\toutput');        
    else
      msg = msprintf('Unknown port of type %s found', block_type); 
      ratel_log(msg, [fname, 'error']);
      return;
    end //if

    //all ports are wires
    mfprintf(fd, ' wire');
    
    //find port size
    if (strcmp(block_type, "inport") == 0) then 
      model = port.model;
      parameters = model.opar(1);
      mfprintf(fd, ' [%d-1:0]', parameters.out.nbits);
    end //if
    
    //find port label
    graphics = port.graphics;
    label = graphics.exprs(1);
    mfprintf(fd, ' %s;\n', label);
  end //for
  ok = %T;
endfunction //ratel_ports2verilog

function[ok] = ratel_verilog_intro(fd, module_name, ports)
//generate the start of a verilog file
  ok = %F; 

  mfprintf(fd, '//Generated by ratel version %s\n', ratel_version());
  mfprintf(fd, 'module %s(', module_name); 
  for port_index = 1:length(ports),
    port = ports(port_index);
    port_name = port.graphics.exprs(1);
    if port_index ~= 1 mfprintf(fd, ', '); end //if
    mfprintf(fd, '%s', port_name);
  end //for	
  mfprintf(fd, ');\n');  

  ok = %T;
endfunction //ratel_verilog_intro
