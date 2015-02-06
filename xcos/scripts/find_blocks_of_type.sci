function[ok, indices] = find_blocks_of_type(gui_name, diagram, levels)
//goes through diagram, finding Blocks with specified type
//optionally decends into subsystems to a depth specified by levels
  ok = %F; indices = list();
  fname = 'find_blocks_of_type';

  for block_index = 1:length(diagram.objs),
    obj = diagram.objs(block_index);
  
    if strcmp(typeof(obj), 'Block') == 0 then
      block_type = obj.gui;

      if strcmp(block_type, gui_name) == 0 then
        indices($+1) = block_index;
      end
      
      //if we have a superblock and been told to descend into it via levels parameter
      if (strcmp(block_type, 'SUPER_f') == 0) & (levels > 0) then
        //get indices from subsystem
        [ko, super_indices] = find_blocks_of_type(gui_name, obj.model.rpar, levels-1);
        if ~ko,
          msg = msprintf('error getting indices of %s blocks from superblock\n', gui_name);
          ratel_log(msg, [fname, 'error']);
        end //if
        msg = msprintf('found %d indices\n', length(super_indices));
        ratel_log(msg, [fname, 'debug']);

        //append new lookup indices to those already found
        for super_idx = 1:length(super_indices),
          super_lookup = super_indices(super_idx);
          indices($+1) = [block_index, super_lookup(:)];
        end //for
      end //if 
    end //if
  end //for

  ok = %T;
endfunction //ratel_find_blocks_of_type
