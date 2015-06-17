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
