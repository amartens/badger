function[ok] = diagram2verilog(diagram, target)
//generates hierachical verilog for an xcos diagram
//diagram = adjusted top level xcos diagram e.g adjust_diagram(scs_m)
//target = path to superblock within top_diagram to be processed e.g [] for top

  ok = %f;
  fname = 'diagram2verilog';  

  if strcmp(typeof(diagram), 'diagram'),
    msg = msprintf('''%s'' passed instead of ''diagram''', typeof(diagram));
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end
  
  //TODO more error checking

  //locate diagram within diagram based on target index
  ratel_log('locating target diagram \n', [fname]);
  for index = 1:length(target),
    offset = target(index);
    if offset > length(diagram.objs),
      msg = msprintf('block with offset %d does not exist in %s', offset, diagram.props.title);
      ratel_log(msg+'\n', [fname, 'error']);
      return;
    end
    //check that it is a diagram
    obj = diagram.objs(offset);
    if strcmp(typeof(obj), 'diagram'),
      msg = msprintf('block with offset %d in %s not a ''diagram'' as required', offset, diagram.props.title);
      ratel_log(msg+'\n', [fname, 'error']);
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
    msg = msprintf('error creating directory %s while in %s', diagname, pwd());
    ratel_log(msg+'\n',[fname, 'error']);
    return;
  end 

  //go into directory we just created 
  ratel_log(msprintf('changing directory to %s', diagname)+'\n', [fname]);
  ko = chdir(diagname);
  if ~ko,
    msg = msprintf('error changing current directory to %s from %s', diagname, pwd());
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end

  //create or clear top file for writing
  ratel_log(msprintf('creating top.v for %s', diagname)+'\n', [fname]);
  [fd, err] = mopen('top.v', 'w');
  //TODO error checking

  //verilog intro
  ratel_log('generating verilog intro\n', [fname]);
  [ko] = verilog_intro(fd, diagram, list());

  //create links
  //[ok] = links2verilog(fd, links, objects);
  //if ~ok then
  //  ratel_log('error translating links\n', [fname, 'error']);
  //  return;
  //end //if

  //create blocks
  //[ok] = blocks2verilog(fd, blocks, links); 
  //if ~ok ten
  //  ratel_log('error translating blocks\n', [fname, 'error']);
  //  return;
  //end //if

  //verilog epilogue
  [ko] = verilog_epilogue(fd, diagname);
  if ~ko then
    ratel_log(msprintf('error writing epilogue for %s', diagname) + '\n', [fname, 'error']);
    return;
  end //if

  //close file
  mclose(fd);

  ok = %t;
endfunction //diagram2verilog

function[ok] = verilog_intro(fd, diagram, offset)
//generate the start of a verilog file including ports
//fd = target file to write intro in
//diagram = adjusted diagram to generate intro for e.g. adjust_diagram(scs_m)
//target = list index of target superblock within diagram

  ok = %f; 
  fname = 'verilog_intro';

  diagname = diagram.props.title; 

  mfprintf(fd, '//Generated by ratel version %s\n', ratel_version());
  mfprintf(fd, 'module %s(', diagname); 

  //we will use inports and outports to connect our logic to the outside world
  //for simulation and connection to busses etc
  
  //find all inports in our diagram (including in all superblocks)
  [ok, inports] = ratel_blk_info('inport', diagram, offset, cor, blklst, %inf);
  if ~ok,
    ratel_log(msprintf('error while finding inports within %d', diagname)+'\n', [fname, 'error']);
    return;
  end
  
  //find all outports in our diagram (including in all superblocks)
  [ok, outports] = ratel_blk_info('outport', diagram, offset, cor, blklst, %inf);
  if ~ok,
    ratel_log(msprintf('error while finding outports within %d', diagname)+'\n', [fname, 'error']);
    return;
  end

  //find all IN_fs in our diagram
  [ok, inf_objs, inf_indices, inf_blks] = ratel_blk_info('IN_f', diagram, offset, cor, blklst, 0);
  if ~ok,
    ratel_log(msprintf('error while finding IN_fs within %d', diagname)+'\n', [fname, 'error']);
    return;
  end
  
  //find all OUT_fs in our diagram
  [ok, outf_objs, outf_indices, outf_blks] = ratel_blk_info('OUT_f', diagram, offset, cor, blklst, 0);
  if ~ok,
    ratel_log(msprintf('error while finding OUT_fs within %d', diagname)+'\n', [fname, 'error']);
    return;
  end

  //TODO find all GOTOs and FROMs

  ports = list(inport_objs(:), outport_objs(:), inf_objs(:), outf_objs(:));
  for port_index = 1:length(ports),
    port = ports(port_index);
    port_name = port.graphics.exprs(1);
    if port_index ~= 1 then mfprintf(fd, ', '); end //if
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

  ok = %t;
endfunction //verilog_intro

function[ok] = ports2verilog(fd, in_f, out_f, inports, outports)
//convert ports of different types to verilog
  ok = %f;
  fname = 'ports2verilog';
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
  ok = %t;
endfunction //ports2verilog

function[ok] = verilog_epilogue(fd, module_name)
  ok = %f;
  mfprintf(fd, 'endmodule //%s\n', module_name);
  ok = %t;
endfunction //verilog_epilogue 

function[ok] = blocks2verilog(fd, blocks, links)
  //TODO
  ok = %t;
endfunction //blocks2verilog

function[ok] = links2verilog(fd, links, objects)
//convert xcos links to verilog wires
  ok = %f;
  fname = 'links2verilog';
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
      msg = msprintf('source index (%d) for link (%d) exceeds number of blocks (%d)', source_index, link_index, length(objects));
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
  ok = %t;
endfunction //links2verilog




