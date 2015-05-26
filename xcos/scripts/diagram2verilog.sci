function[ok] = diagram2verilog(diagram, target)
//generates hierachical verilog for an xcos diagram
//diagram = adjusted top level xcos diagram e.g adjust_diagram(preprocess_diagram(scs_m))
//target = path to superblock within top_diagram to be processed e.g [] for top

  ok = %f;
  fname = 'diagram2verilog';  

  if strcmp(typeof(diagram), 'diagram'),
    msg = msprintf('%s passed instead of diagram', typeof(diagram))
    ratel_log(msg+'\n', [fname, 'error'])
    return;
  end
  
  //TODO check target type

  dtitle = diagram.props.title

  //locate target diagram within top level diagram based on target index
  ratel_log('locating target diagram \n', [fname])
  for index = 1:length(target),
    offset = target(index);
    if offset > length(diagram.objs),
      msg = msprintf('block with offset %d does not exist in %s', offset, dtitle)
      ratel_log(msg+'\n', [fname, 'error'])
      return;
    end
    //check that it is a diagram
    obj = diagram.objs(offset)
    if strcmp(typeof(obj), 'diagram'),
      msg = msprintf('block with offset %d in %s not a ''diagram'' as required', offset, dtitle)
      ratel_log(msg+'\n', [fname, 'error'])
      return
    end
    diagram = obj.model.rpar
  end
 
  //create directory based on diagram name
  //we create a special directory as we may place other things here in future
  ratel_log(msprintf('creating %s', dtitle)+'\n', [fname])
  ko = mkdir(dtitle)
  if ~ko,
    msg = msprintf('error creating directory %s while in %s', dtitle, pwd())
    ratel_log(msg+'\n',[fname, 'error'])
    return
  end 

  //go into directory we just created 
  ratel_log(msprintf('changing directory to %s', dtitle)+'\n', [fname])
  ko = chdir(dtitle)
  if ~ko,
    msg = msprintf('error changing current directory to %s from %s', dtitle, pwd())
    ratel_log(msg+'\n', [fname, 'error'])
    return
  end

  //create or clear top file for writing
  ratel_log(msprintf('creating top.v for %s', dtitle)+'\n', [fname])
  [fd, err] = mopen('top.v', 'w')
  //TODO error checking

  //verilog intro
  ratel_log('generating verilog module definition\n', [fname])
  [ko] = verilog_intro(fd, diagram, [])
  if ~ko then
    ratel_log('error generating verilog module definition\n', [fname, 'error'])
    return
  end //if

  //create blocks
  ratel_log('processing blocks\n', [fname])
  [diagram_hdl, ko] = blocks2verilog(fd, diagram)
  if ~ko then
    ratel_log('error translating blocks to HDL\n', [fname, 'error'])
    return
  end //if

  //create links
  ratel_log('processing links\n', [fname]);
  [ko] = links2verilog(fd, diagram_hdl);
  if ~ko then
    ratel_log('error translating links to HDL\n', [fname, 'error']);
    return;
  end //if

  //verilog epilogue
  ratel_log('closing off verilog module definition\n', [fname])
  [ko] = verilog_epilogue(fd, dtitle)
  if ~ko then
    ratel_log(msprintf('error writing epilogue for %s', dtitle) + '\n', [fname, 'error'])
    return
  end //if

  //move back up in directory structure
  chdir('../')

  //close file
  mclose(fd)

  ok = %t
endfunction //diagram2verilog

function[ok] = verilog_intro(fd, diagram, offset)
//generate the start of a verilog file including ports
//fd = target file to write intro in
//diagram = adjusted diagram to generate intro for e.g. adjust_diagram(scs_m)
//offset = list index of target superblock within diagram

  ok = %f
  fname = 'verilog_intro'

  dtitle = diagram.props.title 

  //we will use inports and outports to connect our logic to the outside world
  //for simulation and connection to busses etc

  //find all inports in our diagram (including in all superblocks)
  [inports, inports_indices, ko] = find_blocks_of_type('inport', diagram, %inf)
  if ~ko,
    ratel_log(msprintf('error finding inports in %s', dtitle)+'\n', [fname, 'error'])
    return
  end
  inports_nbits = list(); inports_directions = list()
  for idx = 1:length(inports),
    port = inports(idx)
    nbits = port.model.outnbits
    if isempty(nbits),
      msg = msprintf('port %s has empty dimensions', port.graphics.exprs(1))
      ratel_log(msg+'\n', [fname, 'error'])
      return
    end //if
    if nbits < 0,
      msg = msprintf('port %s has not resolved dimensions yet', port.graphics.exprs(1))
      ratel_log(msg+'\n', [fname, 'error'])
      return
    end //if
    inports_nbits($+1) = nbits
    inports_directions($+1) = 'input'
  end //for

  //find all outports in our diagram (including in all superblocks)
  [outports, outport_indices, ko] = find_blocks_of_type('outport', diagram, %inf)
  if ~ko,
    ratel_log(msprintf('error while finding outports in %s', dtitle)+'\n', [fname, 'error'])
    return
  end
  
  outports_nbits = list(); outports_directions = list()
  for idx = 1:length(outports),
    port = outports(idx)
    nbits = port.model.innbits
    if isempty(nbits),
      msg = msprintf('port %s has empty dimensions', port.graphics.exprs(1))
      ratel_log(msg+'\n', [fname, 'error'])
      return
    end //if
    if nbits < 0,
      msg = msprintf('port %s has not resolved dimensions yet', port.graphics.exprs(1))
      ratel_log(msg+'\n', [fname, 'error'])
      return
    end //if
    outports_nbits($+1) = nbits
    outports_directions($+1) = 'output'
  end //for

  //find all inouts in top level of our diagram
  [inouts, inout_indices, ko] = find_blocks_of_type('inout', diagram, 0)
  if ~ko,
    ratel_log(msprintf('error while finding inouts in %s', dtitle)+'\n', [fname, 'error'])
    return
  end

  inoutports_nbits = list(); inoutports_directions = list()
  for idx = 1:length(inouts),
    port = inouts(idx)
    nbits = port.model.innbits
    if isempty(nbits),
      msg = msprintf('port %s has empty dimensions', port.graphics.exprs(1))
      ratel_log(msg+'\n', [fname, 'error'])
      return
    end //if
    if nbits < 0,
      msg = msprintf('port %s has not resolved dimensions yet', port.graphics.exprs(1))
      ratel_log(msg+'\n', [fname, 'error'])
      return
    end //if
    inoutports_nbits($+1) = nbits
    iotype = port.model.ipar
    if iotype == 0,
      inoutports_directions($+1) = 'output'
    elseif iotype == 1,
      inoutports_directions($+1) = 'input'
    else,
      msg = msprintf('port %s has unrecognised type %d', port.graphics.exprs(1), iotype)
      ratel_log(msg+'\n', [fname, 'error'])
      return
    end //if iotype
  end //for

  mfprintf(fd, '//Generated by ratel version %s\n', ratel_version())
  mfprintf(fd, 'module %s\n', dtitle)
  mfprintf(fd, '\t(') //beginning of ports

  mfprintf(fd, '\n// inports\n') 
  [ko] = ports2verilog(fd, inports_directions, inports_nbits, inports)
  if ~ko,
    ratel_log(msprintf('error generating inport ports for %s', dtitle)+'\n', [fname, 'error'])
    return
  end
  //add comma if non zeros outports to be added
  if ~isempty(outports_nbits) & ~isempty(find(outports_nbits(:) > 0)), mfprintf(fd, ','); end   

  mfprintf(fd, '\n// outports\n')
  [ko] = ports2verilog(fd, outports_directions, outports_nbits, outports)
  if ~ko,
    ratel_log(msprintf('error generating outport ports for %s', dtitle)+'\n', [fname, 'error'])
    return
  end
  //add comma if non zero standard ports to be added
  if ~isempty(inoutports_nbits) & ~isempty(find(inoutports_nbits(:) > 0)), mfprintf(fd, ','); end   

  mfprintf(fd, '\n// standard ports\n')
  [ko] = ports2verilog(fd, inoutports_directions, inoutports_nbits, inouts)
  if ~ko,
    ratel_log(msprintf('error generating inout ports for %s', dtitle)+'\n', [fname, 'error'])
    return
  end
  
  mfprintf(fd, '\n\t);\n') //end of ports

  ok = %t;
endfunction //verilog_intro

function[ok] = ports2verilog(fd, ports_directions, ports_nbits, ports)
//convert ports of different types to verilog
//ports_directions are 'input' or 'output' for each port
//ports_n_bits_in are the bit width for each port
//ports are the port objects

  ok = %f; fname = 'ports2verilog'
  
  for idx = 1:length(ports),
    port_nbits = ports_nbits(idx)
    //0 sized ports are allowed but not implemented
    if port_nbits > 0,
      port_direction = ports_directions(idx)
      port = ports(idx)
      port_name = port.graphics.exprs(1)
      
      mfprintf(fd, '\t%s ', port_direction)
      if port_nbits > 1,
        mfprintf(fd, '[%d-1:0] ', port_nbits)
      end //if
      mfprintf(fd,' %s', port_name)
      if idx ~= length(ports), mfprintf(fd, ',\n'); end
    end //if

  end //for
  ok = %t
endfunction //ports2verilog

function[ok] = verilog_epilogue(fd, module_name)
  ok = %f;
  mfprintf(fd, 'endmodule //%s\n', module_name);
  ok = %t;
endfunction //verilog_epilogue 

function[diagram_hdl, ok] = blocks2verilog(fd, diagram)
//convert xcos blocks in diagram to verilog
  ok = %f; diagram_hdl = []; fname = 'blocks2verilog';
  ignore_blocks = ['inport', 'outport', 'inout'] //TODO other block types?

  for index = 1:length(diagram.objs),
    obj = diagram.objs(index)
    //we only convert blocks with fixed point models to verilog
    if typeof(obj) == 'Block' & typeof(obj.model) == 'fpmodel',
      [blk, ko] = block_adjust('hdl', obj),
      if ~ko,
        msg = msprintf('error while getting hdl info for %s %d:', obj.gui, index)
        ratel_log(msg+'\n', ['error', fname])
      end

      //we will need some of this info for links etc so save it
      diagram.objs(index) = blk;
 
      //we ignore certain blocks as they are handled differently
      if ~or(obj.gui==ignore_blocks) then
        ratel_log(msprintf('converting %s to verilog', blk.graphics.id)+'\n', [fname])
        ko = block2verilog(fd, blk)
        if ~ko,
          ratel_log(msprintf('error while converting %s to verilog', blk.graphics.id)+'\n', {'error', [fname]})
        end //if
      end //if
    end //if 
  end //for 
  diagram_hdl = diagram
  ok = %t;
endfunction //blocks2verilog

function[ok] = block2verilog(fd, blk)
  ok = %f

  //*************************//
  // determine name of block //
  //*************************//

  gui = blk.gui; id = blk.graphics.id; label = blk.model.label;   
  
  //use graphical id if available
  if ~isempty(id), blk_name = id;
  //use model label if available
  elseif ~isempty(label), blk_name = label;
  //use block type and index
  else, blk_name = msprintf('%s%d', gui, index);
  end

      //mfprintf(fd, '\twire %s;\n', link_name);
  //input labels
  //TODO

  //output labels
  //TODO

  //clocks in

  //clocks out

  ok = %t
endfunction //block2verilog

function[ok] = links2verilog(fd, diagram)
//convert xcos links in diagram to verilog
  ok = %f;
  fname = 'links2verilog';

  for index = 1:length(diagram.objs),
    obj = diagram.objs(index);
    if typeof(obj) == 'Link' then
      lnk = obj;
      
      from_index = lnk.from(1);
      from_port = lnk.from(2);
      from_type = lnk.from(3); 

      to_index = lnk.to(1);
      to_port = lnk.to(2);
      to_type = lnk.to(3); 

      //we use the block with the output port as the name
      if from_type == 0 then
        source_index = from_index; source_port = from_port;
        tgt_index = to_index; tgt_port = to_port;
      else
        source_index = to_index; source_port = to_port;
        tgt_index = from_index; tgt_port = from_port;
      end //if

      if source_index > length(diagram.objs),
        msg = msprintf('source index (%d) for link (%d) exceeds number of blocks (%d)', source_index, link_index, length(diagram.objs));
        ratel_log(msg+'\n', [fname, 'error']);
        return;
      end

      source_block = diagram.objs(source_index);
      if typeof(source_block) ~= 'Block',
        ratel_log(mprintf('need a Block as link source not %s',typeof(source_block))+'\n', [fname, 'error']);
        return
      end
      if typeof(source_block.model) ~= 'fpmodel',
        ratel_log('ignoring link as non fpmodel source Block\n', [fname]);
        continue
      end
      
      if tgt_index > length(diagram.objs),
        msg = msprintf('target index (%d) for link (%d) exceeds number of blocks (%d)', tgt_index, link_index, length(diagram.objs));
        ratel_log(msg+'\n', [fname, 'error']);
        return;
      end

      tgt_block = diagram.objs(tgt_index);
      if typeof(tgt_block) ~= 'Block',
        ratel_log(mprintf('need a Block as link source not %s',typeof(tgt_block))+'\n', [fname, 'error']);
        return
      end
      if typeof(tgt_block.model) ~= 'fpmodel',
        ratel_log('ignoring link as non fpmodel target Block\n', [fname]);
        continue
      end

      src_g = source_block.graphics;
      if source_port > length(src_g.out_label),
        ratel_log('link source port does not have a label\n', [fname, 'error']);
        return
      end
      //we generate the wire names from combination of id and port name (see block2verilog) 
      src_name = msprintf('%s%s', src_g.id, src_g.out_label(source_port));
      
      tgt_g = tgt_block.graphics;
      if tgt_port > length(tgt_g.in_label),
        ratel_log('link target port does not have a label\n', [fname, 'error']);
        return
      end
      //we generate the wire names from combination of id and port name (see block2verilog) 
      tgt_name = msprintf('%s%s', tgt_g.id, tgt_g.in_label(tgt_port));

      //TODO how do clock links work?

      mfprintf(fd, '\tassign %s = %s;\n', tgt_name, src_name)

    end //if     
  end //for
  ok = %t;
endfunction //links2verilog
