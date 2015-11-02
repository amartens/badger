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

function [x, y, typ] = inout(job, arg1, arg2)
//a helper block inserted to ease creation of verilog ports
  x = []; y = []; typ = [];
  select job
    case 'define' then
      model = scicos_model();

      model.sim = list('inout', 4)

      //all input parameters are determined from source    
      model.in = 1; model.intyp = [-1];  
      
      //all output parameters are determined from source    
      model.out = 1; model.outtyp = [-1]; 
      
      model.ipar = arg1; //1 = input, 0 = output

      //create scicos block with standard settings  
      //id, input and outputs labels are all port name
      x = ratel_block_gen([2 1], model, [arg2], [''], ['']);
  end
endfunction
