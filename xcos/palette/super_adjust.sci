function [x] = super_adjust(job, arg1)
  x = []
  fname = 'super_adjust';
  select job
    case 'fp' then
      ratel_log('calculating ''super'' output fixed point info\n', [fname])
      x = arg1
    case 'hdl' then
      //in this case arg1 is an object consisting of fpmodel, graphics etc
      ratel_log('adjusting graphics info for ''super'' hdl generation\n', [fname]);
      x = arg1
  end //select
endfunction
