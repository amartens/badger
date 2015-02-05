function [x] = inport_adjust(job, arg1)
  fname = 'inport_adjust';
  x = [];
  select job
    case 'adjust' then
      ratel_log('calculating input data info', [fname]);
      x = arg1; //do nothing
    end
endfunction
