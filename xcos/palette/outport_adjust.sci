function [x] = outport_adjust(job, arg1)
  fname = 'outport_adjust';
  x = [];
  select job
    case 'adjust' then
      ratel_log('calculating output data info', [fname]);
      x = arg1; //do nothing
    end
endfunction
