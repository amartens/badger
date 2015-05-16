function [x] = inport_adjust(job, arg1)
  x = []
  fname = 'inport_adjust';
  select job
    case 'fp' then
      ratel_log('calculating output fixed point info\n', [fname])
      blk = arg1
      blk.outsign = blk.ipar(1); blk.outnbits = blk.ipar(2); blk.outbinpt = blk.ipar(3)
      x = blk;
    case 'hdl' then
      ratel_log('adjusting graphics info for hdl generation\n', [fname]);
  end
endfunction
