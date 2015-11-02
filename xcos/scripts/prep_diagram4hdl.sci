//This file is part of ratel.
//
//    ratel is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ratel is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with ratel.  If not, see <http://www.gnu.org/licenses/>.

function [prepped_diagram, ok] = prep_diagram4hdl(diagram)
//prepares diagram for hdl generation
//diagram = adjusted diagram 
  fname = 'prep_diagram4hdl'
  prepped_diagram = []; ok = %f 
 
  for index = 1:length(diagram.objs),
    obj = diagram.objs(index)
    //we only convert blocks with fixed point models to verilog
    if typeof(obj) == 'Block' & typeof(obj.model) == 'fpmodel',
      //we ask block specific function to update anything it needs to
      [blk, ko] = block_adjust('hdl', obj),
      if ~ko,
        msg = msprintf('error while getting hdl info for %s %d:', obj.gui, index)
        ratel_log(msg+'\n', ['error', fname])
      end

      //we determine a unique name to reference the block by
      //when generating hdl instance
      block_name = determine_blk_name(blk, index)

      //handle superblocks
      if blk.model.sim == 'super',
        //superblocks are special because these are not in library but generated locally
        //so we save the module name, and generate instance name from that
        blk.model.label = block_name
        block_name = msprintf('my_%s', block_name)
        ratel_log(msprintf('prepping superblock %s for hdl', block_name)+'\n', [fname])
        [prepped_super, ko] = prep_diagram4hdl(obj.model.rpar)
        if ~ko, 
          ratel_log(msprintf('error while prepping superblock %s for hdl', block_name)+'\n', ['error', fname])
          return
        end //if
        blk.model.rpar = prepped_super 
      end //if
      
      //save block name
      blk.graphics.id = block_name
  
      //update diagram with updated block
      diagram.objs(index) = blk

    end //if typeof(obj)
  end //for 
  
  prepped_diagram = diagram
  ok = %t
endfunction //prep_diagram4hdl

function[blk_name] = determine_blk_name(blk, index)
  //instance
  gui = blk.gui; id = blk.graphics.id; 
  label = blk.model.label; exprs = blk.graphics.exprs(1)   

  //use graphical id if available
  if ~isempty(id), blk_name = id
  //use model label if available
  elseif ~isempty(label), blk_name = label
  //use label show graphically if there
  elseif ~isempty(exprs), blk_name = exprs
  //use block type and index
  else, blk_name = msprintf('%s%d', gui, index)
  end
  
endfunction //determine_block_name

