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

function [x, y, typ] = outport(job, arg1, arg2)
  x = []; y = []; typ = [];
  select job
    case 'set' then
      x=arg1;
      graphics=arg1.graphics;
      model=arg1.model;
      exprs=graphics.exprs;

      while %t do
        [ok, label]=scicos_getvalue("outport settings",..
                 ["label"], list('str', -1), [exprs(1)]);
        if ~ok then
          break
        end
        break
      end //while
        
      if ok then
        x.model=model
        exprs(1) = label
        graphics.exprs = exprs
        x.graphics = graphics
      end //if

    case 'define' then
      model = scicos_model()
      model.sim = list('outport', 4); //TODO version 4?
      model.out = 1; model.outtyp = [-2]
      model.in = 1; model.intyp = [-1]
      //create scicos block with standard settings
      //TODO make graphics nicer
      x = ratel_block_gen([2 1], model, [""], [], ['sim'])
  end
endfunction
