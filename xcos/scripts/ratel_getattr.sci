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
    case 'nbits_in' then
      value = object.opar(1).in.nbits;
    case 'binpt_in' then
      value = object.opar(1).in.binpt;
    case 'sign_out' then
      value = object.opar(1).out.sign;
    case 'nbits_out' then
      value = object.opar(1).out.nbits;
    case 'binpt_out' then
      value = object.opar(1).out.binpt;
    else
      ratel_log(msprintf('unknown attribute %s requested', attribute)+'\n',[fname, 'error']); 
      return;
  end //select

  ok = %t;
endfunction //ratel_getattr
