function[value, ok] = ratel_getattr(object, attribute)
//gets attribute from ratel block. Used to hide inner workings as may change
  ok = %f; value = [];
  fname = 'ratel_getattr'; 
  //TODO error checking

  select attribute
    case 'in_sign' then
      value = object.model.opar(1).in.sign;
    case 'in_n_bits' then
      value = object.model.opar(1).in.n_bits;
    case 'in_bin_pt' then
      value = object.model.opar(1).in.bin_pt;
    case 'out_sign' then
      value = object.model.opar(1).out.sign;
    case 'out_n_bits' then
      value = object.model.opar(1).out.n_bits;
    case 'out_bin_pt' then
      value = object.model.opar(1).out.bin_pt;
    else
      ratel_log(msprintf('unrecognised attribute %s', attribute)+'\n',[fname, 'error']); 
      return;
  end //select

  ok = %t;
endfunction //ratel_getattr
