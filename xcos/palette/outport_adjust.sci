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

function [x] = outport_adjust(job, arg1)
  fname = 'outport_adjust';
  x = [];
  select job
    case 'fp' then
      ratel_log('calculating ''outport'' output fixed point info\n', [fname])
      x = arg1; //do nothing
    case 'hdl' then
      //in this case arg1 is an object consisting of fpmodel, graphics etc
      ratel_log('adjusting graphics info for ''outport'' hdl generation\n', [fname]);
      obj = arg1
      obj.graphics.in_label = ''
      x = obj
  end //select
endfunction
