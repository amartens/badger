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

function [x] = inout_adjust(job, arg1)
  x = []
  fname = 'inout_adjust';
  select job
    case 'fp' then
      ratel_log('calculating ''inout'' output fixed point info\n', [fname])
      fpm = arg1
      if(fpm.insign >= 0),
        fpm.outsign = fpm.insign
      end 
      if(fpm.innbits >= 0),
        fpm.outnbits = fpm.innbits
      end 
      if(fpm.inbinpt >= 0),
        fpm.outbinpt = fpm.inbinpt
      end 

      x = fpm
    case 'hdl' then
      //in this case arg1 is an object consisting of fpmodel, graphics etc
      ratel_log('adjusting graphics info for ''inout'' hdl generation\n', [fname]);
      x = arg1
  end //select
endfunction
