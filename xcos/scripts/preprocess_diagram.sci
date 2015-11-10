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

function[preprocessed_diagram, ok] = preprocess_diagram(diagram)
//preprocesses a diagram for HDL generation
//diagram = xcos diagram (eg scs_m)
//preprocessed_diagram = diagram ready for adjusting

  ok = %f; preprocessed_diagram = []; 
  fname = 'preprocess_diagram';

  if strcmp(typeof(diagram), 'diagram'),
    ratel_log(msprintf('%s passed instead of diagram', typeof(diagram))+'\n', [fname, 'error']);
    return;
  end

  dtitle = diagram.props.title;
  temp = diagram;

  //change port output data types of blocks where appropriate to fixed point type.
  //this will propagate when adjust_typ is called
  ratel_log(msprintf('converting output type of blocks to fixed point in %s',dtitle)+'\n', [fname]);
  [temp, ko] = introduce_fixed_point(temp)
  if ~ko,
    msg = msprintf('error while converting output ports of some blocks to fixed point in %s',dtitle);
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end 

  //TODO bubble inport and outport links to top by searching in all component superblocks for
  //inports and outports, and creating input and output ports and links in diagram

  ratel_log(msprintf('bubbling in/outports to top of diagram %s',dtitle)+'\n', [fname]);
  [temp, ko] = bubble_inoutports(temp);
  if ~ko,
    msg = msprintf('error while bubbling inouports of diagram %s',dtitle);
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end 
  
  //TODO replace local GOTOs with real links
 
  //TODO replace global GOTOs with real links. This may be easiest done by using c_pass1 to 
  //get connection info, then updating diagram using this

  //add blocks to be used during port creation to determine port characteristics
  ratel_log(msprintf('adding port creation helper blocks to %s',dtitle)+'\n', [fname]);
  [temp, ko] = add_port_helpers(temp);
  if ~ko,
    msg = msprintf('error adding port creation helper blocks to diagram %s',dtitle);
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end 

  preprocessed_diagram = temp;
  ok = %t;
endfunction //preprocess_diagram

function[diagram_with_fp, ok] = introduce_fixed_point(diagram)
//converts output ports of certain blocks to fixed point type
  diagram_with_fp = []; ok = %f
  fname = 'introduce_fixed_point'
  fpblocks = ['inport'] //TODO other block types?

  temp = diagram;
  for i = 1:length(temp.objs), 
    obj = temp.objs(i)
    if typeof(obj) == 'Block',
      if or(obj.gui==fpblocks),
        msg = msprintf('introducing fixed point to %s at offset %d', obj.gui, i)
        ratel_log(msg+'\n', [fname])
        
        //convert all output ports to fixed point type
        obj.model.outtyp = repmat(9, length(obj.model.outtyp), 1)
        temp.objs(i) = obj
      elseif obj.model.sim=="super"|obj.model.sim=="csuper",
        msg = msprintf('introducing fixed point to superblock at offset %d', i)
        ratel_log(msg+'\n', [fname])
        
        //update superblock
        [updated_super, ko] = introduce_fixed_point(obj.model.rpar)
        if ~ko,
          msg = msprintf('error while introducing fixed point in superblock found at %d', i)
          ratel_log(msg+'\n', [fname, 'error'])
        end //if
      
        //update diagram with updated super block
        temp.objs(i).model.rpar = updated_super
      end //if fpblocks
    end //if Block
  end //for
  diagram_with_fp = temp; ok = %t
endfunction //introduce_fixed_point

//TODO
function[bubbled_diagram, ok] = bubble_inoutports(diagram)
//bubbles in/outports to top of diagram by creating them at the top level and
//then descending into superblocks, adding links and removing the original ports
  bubbled_diagram = []; ok = %f
  fname = 'bubble_inoutports'
  temp = diagram

  //find all inports in system
  ratel_log('locating inports\n', [fname])
  [inports, iindices, ko] = find_blocks_of_type('inport', temp, %inf)
  if ~ko,  
    msg = msprintf('error while locating inports')
    ratel_log(msg+'\n', [fname, 'error'])
  end //if
  msg = msprintf('%d inports found\n', length(inports))
  ratel_log(msg+'\n', [fname])

  //go through inports
  for inport_index = 1:length(inports),
    //add new inport in top system
    inport = inports(inport_index); inport_indices = iindices(inport_index)
    lo = length(temp.objs)

    //if inport is at top level, skip
    if length(inport_indices) == 1,
      msg = msprintf('skipping inport ''%s'' at top level', inport.graphics.exprs(1))
      ratel_log(msg+'\n', [fname])
      continue
    else,
      msg = msprintf('adding inport ''%s'' to top at position %d', inport.graphics.exprs(1), lo)
      ratel_log(msg+'\n', [fname])
    end

    src = inport
 
    //go through indices for each inport
    for index = 1:length(inport_indices),


    end //for
  end //for

  bubbled_diagram = temp; ok = %t
endfunction //bubble_inoutports

function[bubbled_diagram, ok] = bubble_port(diagram, location)
//bubbles a single in/outport up from location within diagram using recursion
//at lowest level in/outport is replaced with in/out gateway
  bubbled_diagram = []; ok = %f

  //if at bottom level
  if index == length(inport_indices),
    //remove inport
    //replace with input gateway
    ingi = index  
  else,
    //add new input gateway
    ingi = length(temp.objs)+1

    //add link from src to superblock
    
    //modify superblock model to include src
    temp.objs($+1) = src
    //go into superblock
    src = temp.objs(index)
    temp = temp.objs(index).model.rpar
  end //if

endfunction //bubble_port

function[diagram_with_helpers, ok] = add_port_helpers(diagram)
//adds blocks after input ports and before output ports that will not
//be removed during c_pass1 that will help when generating HDL

  diagram_with_helpers = []; ok = %f;
  fname = 'add_port_helpers';
  in_blocks=["IN_f","INIMPL_f","CLKIN_f","CLKINV_f"]
  out_blocks=["OUT_f","OUTIMPL_f","CLKOUT_f","CLKOUTV_f"]
  d_temp = diagram
 
  //no error checking as check done in calling function
  //that faces externally
 
  for obj_i = 1:length(d_temp.objs),
    obj = d_temp.objs(obj_i);
    n_objs = length(d_temp.objs)

    if typeof(obj) == 'Block' then
      //process input port blocks
      if or(obj.gui==in_blocks) then
        msg = msprintf('processing %s(%d)', obj.gui, obj.model.ipar);
        ratel_log(msg+'\n', [fname]);

        //new link between input port and helper
        lnk = scicos_link()
        lnk.id = 'helper'
        lnk.from = [obj_i, 1, 0]
        lnk.to = [n_objs+1, 1, 1] 

        //construct input helper block
        io = inout('define', 1, msprintf('%s%s', obj.gui, obj.graphics.exprs(1)))
        pout = obj.graphics.pout    

        //link helper to input port's links
        io.graphics.pout = pout       
        //link helper to new link to input port
        io.graphics.pin = n_objs+2
        //change input port's link
        obj.graphics.pout = n_objs+2

        //insert new object, new link, and updated object
        d_temp.objs(n_objs+1) = io
        d_temp.objs(n_objs+2) = lnk
        d_temp.objs(obj_i) = obj
    
        //lastly update existing links to point to helper as source
        d_temp.objs(pout).from = [n_objs+1, 1, 0]

      elseif or(obj.gui==out_blocks) then
        msg = msprintf('processing %s(%d)', obj.gui, obj.model.ipar);
        ratel_log(msg+'\n', [fname]);

        //new link between helper and output port
        lnk = scicos_link()
        lnk.id = 'helper'
        lnk.from = [n_objs+1, 1, 0]
        lnk.to = [obj_i, 1, 1] 

        //construct output helper block
        io = inout('define', 0, msprintf('%s%s', obj.gui, obj.graphics.exprs(1)))
        pin = obj.graphics.pin
        //link helper to link into output port
        io.graphics.pin = pin       
        //link helper to new link to output port
        io.graphics.pout = n_objs+2

        obj.graphics.pin = n_objs+2

        //insert new object, new link, and updated object
        d_temp.objs(n_objs+1) = io
        d_temp.objs(n_objs+2) = lnk
        d_temp.objs(obj_i) = obj
    
        //lastly update existing links to point to helper as destination
        d_temp.objs(pin).to = [n_objs+1, 1, 1]

      elseif obj.model.sim=="super"|obj.model.sim=="csuper" then
        msg = msprintf('adding port helpers to superblock at offset %d', obj_i);
        ratel_log(msg+'\n', [fname]);
        
        //update superblock
        [updated_super, ko] = add_port_helpers(obj.model.rpar);
        if ~ko then
          msg = msprintf('error adding port helpers in superblock found at %d', obj_i);
          ratel_log(msg+'\n', [fname, 'error']);
        end //if
      
        //update diagram with updated super block
        d_temp.objs(obj_i).model.rpar = updated_super;
      end //if super
    end //if Block
  end //for

  diagram_with_helpers = d_temp;
  ok = %t;
endfunction //add_port_helpers
