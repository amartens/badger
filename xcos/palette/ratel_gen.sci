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

function [ok] = ratel_gen()
//used to generate ratel palette
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
