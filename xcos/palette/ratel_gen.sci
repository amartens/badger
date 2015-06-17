//used to generate ratel palette
function [ok] = ratel_gen()
  ok = %f

  loadXcosLibs

  //delete if already loaded
  try
    xcosPalDelete('ratel')
  catch
  end

  //construct basic palette
  basic_blocks = list('inport', 'outport')
  [ko, basic_pal] = palette_gen('basic', basic_blocks)
  if ~ok,
    //TODO
  end
  [ko, msg] = xcosPalAdd(basic_pal, 'ratel')
  if ~ok,
    //TODO
  end
  
  ok = %t
endfunction

//create palette with name palette_name and add list of blocks with names in block_names
function [ok, palette] = palette_gen(palette_name, block_names)
  ok = %f 
  palette = xcosPal(palette_name)
  
  for block_index = 1:size(block_names)
    block_name = block_names(block_index)
    ko = delete_icon(block_name)
    if ~ko,
      //TODO
    end

    //this adds a label to the block based on label at first position
    //in graphics.exprs
    style = struct( ..
                    'noLabel', '0', ..
                    'displayedLabel', '%1$s', ..
                    'verticalLabelPosition', 'bottom');
    //block_name must be the same as the interface function
    palette = xcosPalAddBlock(palette, block_name, [], style)
  end

  ok = %t
endfunction

//helper to remove block images that may already exist
function [ok] = delete_icon(block_name)
  ok = %f
  gif_filename = msprintf("%s/%s.gif", TMPDIR, block_name)
  [fd, err] = mopen(gif_filename)
  //if exists
  if (err == 0),
    mclose(fd)
    mdelete(gif_filename)
  end 
  
  svg_filename = msprintf("%s/%s.svg", TMPDIR, block_name)
  [fd, err] = mopen(svg_filename)
  //if exists
  if (err == 0),
    mclose(fd)
    mdelete(svg_filename)
  end 
  ok = %t
endfunction
