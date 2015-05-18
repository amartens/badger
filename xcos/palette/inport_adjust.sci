function [x] = inport_adjust(job, arg1)
  x = []
  fname = 'inport_adjust';
  select job
    case 'fp' then
      ratel_log('calculating ''inport'' output fixed point info\n', [fname])
      fpm = arg1
      fpm.outsign = fpm.ipar(1); fpm.outnbits = fpm.ipar(2); fpm.outbinpt = fpm.ipar(3)
      x = fpm
    case 'hdl' then
      //in this case arg1 is an object consisting of fpmodel, graphics etc
      ratel_log('adjusting graphics info for ''inport'' hdl generation\n', [fname]);
      obj = arg1
      obj.graphics.id = obj.graphics.exprs(1) //use graphical label as hdl label
      obj.graphics.out_label = obj.graphics.exprs(1)
      x = obj
  end //select
endfunction
