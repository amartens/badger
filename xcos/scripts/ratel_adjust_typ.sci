//taken directly from c_pass2.sci
// adjust_typ: It resolves positives and negatives port types.
//		   Its Algorithm is based on the algorithm of adjust_inout
// Fady NASSIF: 14/06/2007

function [ok,bllst]=ratel_adjust_typ(bllst,connectmat)

for i=1:length(bllst)
  if size(bllst(i).in,1)<>size(bllst(i).intyp,2) then
    bllst(i).intyp=bllst(i).intyp(1)*ones(size(bllst(i).in,1),1);
  end
  if size(bllst(i).out,1)<>size(bllst(i).outtyp,2) then
    bllst(i).outtyp=bllst(i).outtyp(1)*ones(size(bllst(i).out,1),1);
  end
end
nlnk=size(connectmat,1) 
for hhjj=1:length(bllst)+1
  for hh=1:length(bllst)+1 
    ok=%t
    for jj=1:nlnk 
      nnout(1,1)=bllst(connectmat(jj,1)).out(connectmat(jj,2))
      nnout(1,2)=bllst(connectmat(jj,1)).out2(connectmat(jj,2))
      nnin(1,1)=bllst(connectmat(jj,3)).in(connectmat(jj,4))
      nnin(1,2)=bllst(connectmat(jj,3)).in2(connectmat(jj,4))
      outtyp = bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))
      intyp = bllst(connectmat(jj,3)).intyp(connectmat(jj,4))
      
      //first case : types of source and
      //             target ports are explicitly informed
      //             with positive types
      if (intyp>0 & outtyp>0) then
	//if types of source and target port doesn't match and aren't double and complex
	//then call bad_connection, set flag ok to false and exit
	
	if intyp<>outtyp then
	  if (intyp==1 & outtyp==2) then
	    bllst(connectmat(jj,3)).intyp(connectmat(jj,4))=2;
	  elseif (intyp==2 & outtyp==1) then
	    bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))=2;
	  else
	    bad_connection(corinv(connectmat(jj,1)),connectmat(jj,2),..
		nnout,outtyp,..
		corinv(connectmat(jj,3)),connectmat(jj,4),..
		nnin,intyp,1)
	    ok=%f;
	    return
	  end
	end
	
	//second case : type of source port is
	//              positive and type of
	//              target port is negative
      elseif(outtyp>0&intyp<0) then
	//find vector of input ports of target block with
	//type equal to intyp
	//and assign it to outtyp
	ww=find(bllst(connectmat(jj,3)).intyp==intyp)
	bllst(connectmat(jj,3)).intyp(ww)=outtyp
	
	//find vector of output ports of target block with
	//type equal to intyp
	//and assign it to outtyp
	ww=find(bllst(connectmat(jj,3)).outtyp==intyp)
	bllst(connectmat(jj,3)).outtyp(ww)=outtyp
	
	//third case : type of source port is
	//             negative and type of
	//             target port is positive
      elseif(outtyp<0&intyp>0) then
	//find vector of output ports of source block with
	//type equal to outtyp
	//and assign it to intyp
	ww=find(bllst(connectmat(jj,1)).outtyp==outtyp)
	bllst(connectmat(jj,1)).outtyp(ww)=intyp
	
	//find vector of input ports of source block with
	//type equal to size outtyp
	//and assign it to intyp
	ww=find(bllst(connectmat(jj,1)).intyp==outtyp)
	bllst(connectmat(jj,1)).intyp(ww)=intyp
	
	
	//fourth (& last) case : type of both source 
	//                      and target port are negatives
      else
	ok=%f //set flag ok to false
      end
    end
    if ok then return, end //if ok is set true then exit adjust_typ
  end
  //if failed then display message
  messagebox(msprintf(_('Not enough information to find port type.\n'+..
			'I will try to find the problem.')),"modal","info");
  findflag=%f 
  for jj=1:nlnk 
    nouttyp=bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))
    nintyp=bllst(connectmat(jj,3)).intyp(connectmat(jj,4))
    
    //loop on the two dimensions of source/target port
    //only case : target and source ports are both
    //            negatives or null
    if nouttyp<=0 & nintyp<=0 then
      findflag=%t;
      //
      inouttyp=under_connection(corinv(connectmat(jj,1)),connectmat(jj,2),nouttyp,..
	  corinv(connectmat(jj,3)),connectmat(jj,4),nintyp,2)			   
      //
      if inouttyp<1|inouttyp>8 then ok=%f;return;end
      //
      ww=find(bllst(connectmat(jj,1)).outtyp==nouttyp)
      bllst(connectmat(jj,1)).outtyp(ww)=inouttyp
      
      //
      ww=find(bllst(connectmat(jj,1)).intyp==nouttyp)
      bllst(connectmat(jj,1)).intyp(ww)=inouttyp
      
      ww=find(bllst(connectmat(jj,3)).intyp==nintyp)
      bllst(connectmat(jj,3)).intyp(ww)=inouttyp
      //
      ww=find(bllst(connectmat(jj,3)).outtyp==nintyp)
      bllst(connectmat(jj,3)).outtyp(ww)=inouttyp
      
      //
    end
  end
  //if failed then display message
  if ~findflag then 
    messagebox(msprintf(_('I cannot find a link with undetermined size.\n'+..
			  'My guess is that you have a block with unconnected \n'+..
			  'undetermined types.')),"modal","error");
    ok=%f;return;
  end
end
endfunction
