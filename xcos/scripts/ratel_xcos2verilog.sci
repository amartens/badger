function [ok] = ratel_xcos2verilog(model_path, output_directory)
//function converting an xcos model using ratel library blocks to verilog
  ok = %F;
  //for logging
  fname = 'ratel_xcos2verilog';

  //TODO error checking

  //open model (handle in scs_m after load)
  ratel_log(msprintf('importing %s', model_path)+'\n' , [fname]);
  ko = importXcosDiagram(model_path);
  if ko == %F | ~isdef('scs_m') then
    msg = msprintf('Error importing %s', model_path);
    ratel_log(msg, [fname+'\n', 'error']);
    return;
  end //if

  //we run c_pass1 to do certain connectivity checks and 'flatten' structure
  ratel_log(msprintf('running c_pass1 on %s', scs_m.props.title)+'\n', [fname]);
  [blklst, connectmat, ccmat, cor, corinv, ko]=c_pass1(scs_m);  
  if ~ko then
    ratel_log('error in first pass\n', [fname, 'error']);
    return;
  end
 
  //adjust size of vector passed through ports 
  ratel_log('adjusting inout\n', [fname]);
  [ko, blklst]=ratel_adjust_inout(blklst, connectmat)
  if ~ko then
    ratel_log('error adjusting port inout\n', [fname, 'error']);
    return;
  end
  
  //adjust type of input/output ports
  ratel_log('adjusting type\n', [fname]);
  [ko, blklst]=ratel_adjust_typ(blklst, connectmat)
  if ~ko then
    ratel_log('error adjusting port type\n', [fname, 'error']);
    return;
  end

  //adjust fixed point info for blocks
  ratel_log('adjusting fixed point info\n', [fname]);
  [ko, blklst] = ratel_adjust_fp(blklst, connectmat)
  if ~ko then
    ratel_log('error adjusting fixed point info\n', [fname, 'error']);
    return;
  end

  //change directory to target
  msg = msprintf('changing into %s from %s', output_directory, pwd());
  ratel_log(msg+'\n', [fname]);
  ko = chdir(output_directory);
  if ~ko,
    msg = msprintf('error changing current directory to %s', output_directory);
    ratel_log(msg, [fname+'\n', 'error']);
    return;
  end  
  
  ratel_log(msprintf('generating hdl for diagram %s', model_path)+'\n', [fname]);
  ko = ratel_diagram2verilog(scs_m, blklst, cor, corinv, connectmat, []);

  ok = %T;
endfunction //ratel_xcos2verilog

function[ok] = ratel_diagram2verilog(top_diagram, blklst, cor, corinv, connectmat, target)
//generates hierachical verilog for an xcos diagram
//diagram = top level xcos diagram (e.g scs_m)
//blklst = blocks contained in flattened, and updated structure (c_pass1)
//cor = matrix giving index of diagram block in blklst (c_pass1)
//corinv = matrix giving index of blklst block in diagram
//connectmat = connection matrix (as output from c_pass1)
//target = path to superblock to be processed

  ok = %f;
  fname = 'ratel_diagram2verilog';  

  if strcmp(typeof(top_diagram), 'diagram'),
    ratel_log(msprintf('%s passed instead of diagram', typeof(top_diagram))+'\n', [fname, 'error']);
    return;
  end
  
  //TODO more error checking

  //TODO back up current design?
 
  //locate diagram within top_diagram based on target index
  ratel_log('locating diagram \n', [fname]);
  diagram = top_diagram;
  for index = 1:length(target),
    offset = target(index);
    if offset > length(diagram.objs),
      msg = msprintf('block with offset %d does not exist in %s', offset, diagram.props.title);
      ratel_log(msg, [fname+'\n', 'error']);
      return;
    end
    //check that it is a diagram
    obj = diagram.objs(offset);
    if strcmp(typeof(obj), 'diagram'),
      msg = msprintf('block with offset %d in %s not a diagram as required', offset, diagram.props.title);
      ratel_log(msg, [fname+'\n', 'error']);
      return;
    end
    diagram = obj.model.rpar;
  end
 
  diagname = diagram.props.title; 

  //create directory based on diagram name
  //we create a special directory as we may place other things here in future
  ratel_log(msprintf('creating %s', diagname)+'\n', [fname]);
  ko = mkdir(diagname);
  if ~ko,
    ratel_log(msprintf('error creating directory %s while in %s', diagname, pwd())+'\n',[fname, 'error']);
    return;
  end 

  //go into directory we just created 
  ratel_log(msprintf('changing directory to %s', diagname)+'\n', [fname]);
  ko = chdir(diagname);
  if ~ko,
    msg = msprintf('error changing current directory to %s from %s', diagname, pwd());
    ratel_log(msg, [fname+'\n', 'error']);
    return;
  end

  //create or clear top file for writing
  ratel_log(msprintf('creating top.v for %s', diagname)+'\n', [fname]);
  [fd, err] = mopen('top.v', 'w');
  //TODO error checking

  //verilog intro
  ratel_log('generating verilog intro\n', [fname]);
  [ko] = ratel_verilog_intro(fd, diagram, blklst, cor, list());

  //create links
  //[ok] = ratel_links2verilog(fd, links, objects);
  //if ~ok then
  //  ratel_log('error translating links\n', [fname, 'error']);
  //  return;
  //end //if

  //create blocks
  //[ok] = ratel_blocks2verilog(fd, blocks, links); 
  //if ~ok ten
  //  ratel_log('error translating blocks\n', [fname, 'error']);
  //  return;
  //end //if

  //verilog epilogue
  [ko] = ratel_verilog_epilogue(fd, diagname);
  if ~ko then
    ratel_log(msprintf('error writing epilogue for %s', diagname) + '\n', [fname, 'error']);
    return;
  end //if

  //close file
  mclose(fd);

  ok = %t;

endfunction //ratel_diagram2verilog

function[ok] = ratel_verilog_intro(fd, diagram, blklst, cor, offset)
//generate the start of a verilog file including ports
//fd = target file to write intro in
//diagram = diagram to generate intro for (e.g. scs_m)
//blklst = list of blocks (generated by c_pass1)
//cor = correspondance list giving index in blklst for every block in diagram
//offset = offset within diagram of target (if not the top)

  ok = %F; 
  fname = 'ratel_verilog_intro';

  diagname = diagram.props.title; 

  mfprintf(fd, '//Generated by ratel version %s\n', ratel_version());
  mfprintf(fd, 'module %s(', diagname); 

  //find all inports in all levels
  blk_type = 'inport';
  ratel_log(msprintf('finding %ss in %s ...', blk_type, diagname)+'\n', [fname]);
  [ko, blks, blk_indices] = find_blocks_of_type(blk_type, diagram, %inf); 
  if ~ko then 
    ratel_log(msprintf('error while finding %ss in %d', blk_type, diagname)+'\n', [fname, 'error']);
    return
  end //if
  ratel_log(msprintf('found %d %ss in %s', length(blks), blk_type, diagname)+'\n', [fname]);

  //get blks as contain fixed point info
  for idx = 1:length(blk_indices),
    //TODO check if cor and blklst have these locations
    blk = blks(idx);
    blk_idx = blk_indices(idx);
    location = cor(list(offset(:), blk_idx(:)))
    if location(1) ~= 0 then
      loc_str = '';
      for loci = 1:length(location),
        if loci ~= 1, loc_str = loc_str+','; end //if
        loc_str = loc_str+msprintf('%d',location(loci));
      end //for
      msg = msprintf('found %s %s at location [%s]', blk_type, blk.graphics.exprs(1), loc_str);
      ratel_log(msg+'\n', [fname]);
      
      blk = blklst(location);
      //TODO more stuff with block 
    else,  
      ratel_log(msprintf('%s %s excluded', blk_type, blk.graphics.exprs(1))+'\n', [fname, 'warning']);
    end //if location
  end //for

  //TODO find all IN_fs and OUT_fs
  //TODO find all GOTOs and FROMs

  ports = blks;
  for port_index = 1:length(ports),
    port = ports(port_index);
    port_name = port.graphics.exprs(1);
    if port_index ~= 1 mfprintf(fd, ', '); end //if
    mfprintf(fd, '%s', port_name);
  end //for	
  mfprintf(fd, ');\n');  

  //create ports
//  [ko] = ratel_ports2verilog(fd, in_f, out_f, inports, outports);
//  if ~ok then
//    ratel_log('error translating ports\n', [fname, 'error']);
//    return;
//  end //if
//  mfprintf(fd, '\n');

  ok = %T;
endfunction //ratel_verilog_intro

function[ok] = ratel_ports2verilog(fd, in_f, out_f, inports, outports)
//convert ports of different types to verilog
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
      ratel_log(msg, [fname+'\n', 'error']);
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
      ratel_log(msg+'\n', [fname, 'error']);
      return;
    end

    source_block = objects(source_index);
    //TODO not enough to check for valid ratel block
    if strcmp(typeof(source_block), 'Block') ~= 0,
      ratel_log('not a valid ratel block\n', [fname, 'error']);
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




