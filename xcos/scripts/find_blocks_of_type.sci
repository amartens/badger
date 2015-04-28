function[blocks, indices, ok] = find_blocks_of_type(gui_name, diagram, levels)
//goes through diagram, finding Blocks with specified gui name
//optionally descends into subsystems to a depth specified by levels
//use %inf to descend to all levels, 0 for only top level

  ok = %f; indices = list(); blocks = list();
  fname = 'find_blocks_of_type';

  if strcmp(typeof(diagram), 'diagram'),
    ratel_log(msprintf('%s passed instead of diagram', typeof(diagram))+'\n', [fname, 'error']);
    return;
  end

  //TODO check type of gui_name and levels

  dtitle = diagram.props.title;

  for block_index = 1:length(diagram.objs),
    obj = diagram.objs(block_index);
  
    if strcmp(typeof(obj), 'Block') == 0 then
      block_type = obj.gui;

      //found a block of type requested
      if strcmp(block_type, gui_name) == 0 then
        msg = msprintf('found %s block at index %d in %s', gui_name, block_index, dtitle);
        ratel_log(msg+'\n', [fname]);
        indices($+1) = block_index;
	      blocks($+1) = obj;
      end //if
      
      //if we have a superblock and have been told to descend into it via levels parameter
      if (strcmp(block_type, 'SUPER_f') == 0) & (levels > 0) then
        //get indices from superblock
        msg = msprintf('descending into superblock found at %d', block_index);
        ratel_log(msg+'\n', [fname]);
        [super_blocks, super_indices, ko] = find_blocks_of_type(gui_name, obj.model.rpar, levels-1);
        if ~ko then
          msg = msprintf('error getting indices of %s blocks from superblock', gui_name);
          ratel_log(msg+'\n', [fname, 'error']);
        end //if
        if length(super_blocks) ~= 0 then
          msg = msprintf('found %d %ss in superblock at %d', length(super_blocks), gui_name, block_index);
          ratel_log(msg+'\n', [fname]);
        end

        //append new lookup indices to those already found
        for super_idx = 1:length(super_indices),
          blocks($+1) = super_blocks(super_idx);
          //construct index from offset of superblock and indices returned
          super_lookup = super_indices(super_idx);
          indices($+1) = list(block_index, super_lookup(:));
        end //for
      end //if 
    end //if
  end //for

  //sanity check
  if length(indices) ~= length(blocks),
    ratel_log(msprintf('block indices different length to blocks when finding %s', gui_name)+'\n', [fname, 'error']);
    return
  end
  ok = %t;
endfunction //find_blocks_of_type
