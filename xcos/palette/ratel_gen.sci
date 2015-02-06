//used to generate badger palette
function [status] = ratel_gen()
  status = %f;

  loadXcosLibs;

  //delete if already loaded
  try
    xcosPalDelete('ratel');
  catch
  end

  //construct basic palette
  basic_blocks = list('inport', 'outport');
  [status, basic_pal] = palette_gen('basic', basic_blocks);
//  if (status != %t) then
    //TODO
//  end
  [status, msg] = xcosPalAdd(basic_pal, 'ratel');
//  if (status != %t) then
    //TODO
//  end
  
  //construct math palette
  math_blocks = list('add');
  [status, math_pal] = palette_gen('math', math_blocks);
//  if (status != %t) then
    //TODO
//  end
  [status, msg] = xcosPalAdd(math_pal, 'ratel');
//  if (status != %t) then
    //TODO
//  end
  
  status = %t;
endfunction

//create palette with name palette_name and add list of blocks with names in block_names
function [status, palette] = palette_gen(palette_name, block_names)
  status = %f; 
  palette = xcosPal(palette_name);
  
  for block_index = 1:size(block_names)
    block_name = block_names(block_index);
    delete_icon(block_name);

    //this adds a label to the middle of the block based on label at first position
    //in graphics.exprs
    style = struct( ..
                    'noLabel', '0', ..
                    'displayedLabel', '%1$s', ..
                    'verticalLabelPosition', 'bottom');
    //block_name must be the same as the interface function
    palette = xcosPalAddBlock(palette, block_name, [], style);
  end

  status = %t;
endfunction

//helper to remove block images that may already exist
function [status] = delete_icon(block_name)
  status = %f;
  gif_filename = msprintf("%s/%s.gif", TMPDIR, block_name);
  [fd, err] = mopen(gif_filename);
  //if exists
  if (err == 0) then
    mclose(fd);
    mdelete(gif_filename);
  end 
  
  svg_filename = msprintf("%s/%s.svg", TMPDIR, block_name);
  [fd, err] = mopen(svg_filename);
  //if exists
  if (err == 0) then
    mclose(fd);
    mdelete(svg_filename);
  end 
  status = %t;
endfunction
