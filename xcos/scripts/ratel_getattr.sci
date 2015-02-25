function[value, ok] = ratel_getattr(object, attribute)
//gets attribute from ratel block. Used to hide inner workings as may change
  ok = %f; value = [];
  fname = 'ratel_getattr'; 
  //TODO error checking

  if typeof(object) == 'Block' then
    object = object.model;
  elseif typeof(object) == 'model' then
  else
    msg = msprintf('unrecognised object type %s, expecting ''Block'' or ''model''', typeof(object))
    ratel_log(msg+'\n',[fname, 'error']); 
    return;
  end //if

  select attribute
    case 'sign_in' then
      value = object.opar(1).in.sign;
    case 'n_bits_in' then
      value = object.opar(1).in.n_bits;
    case 'bin_pt_in' then
      value = object.opar(1).in.bin_pt;
    case 'sign_out' then
      value = object.opar(1).out.sign;
    case 'n_bits_out' then
      value = object.opar(1).out.n_bits;
    case 'bin_pt_out' then
      value = object.opar(1).out.bin_pt;
    else
      ratel_log(msprintf('unknown attribute %s requested', attribute)+'\n',[fname, 'error']); 
      return;
  end //select

  ok = %t;
endfunction //ratel_getattr
