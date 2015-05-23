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
      //in/outports have no block id but are uniquely identified by port name
      obj.graphics.id = ''
      obj.graphics.in_label = [obj.graphics.exprs(1)]
      x = obj
  end //select
endfunction
