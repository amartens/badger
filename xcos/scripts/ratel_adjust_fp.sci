function[ok, bllst] = ratel_adjust_fp(bllst, connectmat)
//ratel_adjust_fp: Resolves fp info.
//  based on adjust_inout algorithm
//  Andrew: 05/12/2014

  ok = %F;
  fname = 'ratel_adjust_fp';

  nlnk=size(connectmat,1); //nlnk is the number of link

  //loop on number of block (pass 1 and pass 2)
  for hhjj=1:length(bllst)+1
    //%%%%% pass 1 %%%%%//
    for hh=1:length(bllst)+1 //second loop on number of block
      ok=%T
      for jj=1:nlnk //loop on number of link
        outblk = bllst(connectmat(jj,1)); 
        inblk = bllst(connectmat(jj,3));
        //we only care about links where source and destination
        //blocks use fixed point
        outbt = outblk.blocktype; inbt = inblk.blocktype;
        if (strcmp(outbt, 'f') == 0) & (strcmp(inbt, 'f') == 0) then
          msg = msprintf('processing fixed point link between %d and %d', connectmat(jj,1), connectmat(jj,3));  
          ratel_log(msg+'\n', [fname]);
          //in/outinfo are parameter structs for blocks
          //containing fixed point info for ports
          outinfo = outblk.opar(1).out; ininfo = inblk.opar(1).in;
  
          oport_idx = connectmat(jj,2); iport_idx = connectmat(jj,4);

          //try to get other info.
          //if other info not available, ask block to try calculate it.
          //if still no luck, then mark as negative for this run

          outsign = -1; outnbits = -1; outbinpt = -1;
          if (length(outinfo.sign) >= oport_idx) then 
            outsign = outinfo.sign(oport_idx); 
          end
          if (length(outinfo.nbits) >= oport_idx) then 
            outnbits = outinfo.nbits(oport_idx); 
          end
          if (length(outinfo.binpt) >= oport_idx) then  
            outbinpt = outinfo.binpt(oport_idx);
          end
          
          insign = -1; innbits = -1; inbinpt = -1;
          if (length(ininfo.sign) >= iport_idx) then 
            insign = ininfo.sign(iport_idx); 
          end
          if (length(outinfo.nbits) >= iport_idx) then 
            innbits = ininfo.nbits(iport_idx); 
          end
          if (length(outinfo.binpt) >= iport_idx) then  
            inbinpt = ininfo.binpt(iport_idx);
          end

	  ratel_log('before:\n', [fname]);
          msg = msprintf('out: sign(%d) (%d,%d)', outsign, outnbits, outbinpt);   
          ratel_log(msg+'\n', [fname]);
          msg = msprintf('in: sign(%d) (%d,%d)', insign, innbits, inbinpt);   
          ratel_log(msg+'\n', [fname]);

          //if outsign < 0 | outnbits < 0 | outbinpt < 0 then
          //  outcalc = outinfo.outcalc;  //function to calculate out info
          //  fn_call_str = msprintf('[x] = %s(''adjust'', outblk)', outcalc); 
          //  execstr(fn_call_str);
          //  //TODO how to check for errors? 
          //end
          //bllst(connectmat(jj,1)) = x;
          //outinfo = x.opar(1).out;
          //outsign = -1; outnbits = -1; outbinpt = -1;
          //outsign = outinfo.sign(outport);
          //outnbits = outinfo.nbits(outport);
          //outbinpt = outinfo.binpt(outport);
         
          //if both src and dest are positive but different
          if (insign >= 0) & (outsign >= 0) & (outsign <> insign) then 
            ok = %F;
            ratel_log('sign mismatch\n', [fname, 'error']);
            return;
          elseif insign < 0 & outsign >= 0 then 
            ininfo.sign(iport_idx) = outsign;
          else
            ok = %F;
          end
          
          //if both src and dest are positive but different
          if (innbits >= 0) & (outnbits >= 0) & (outnbits <> innbits) then 
            ok = %F;
            ratel_log('number bits mismatch\n', [fname, 'error']);
            return;
          elseif innbits < 0 & outnbits >= 0 then 
            ininfo.nbits(iport_idx) = outnbits;
          else
            ok = %F;
          end
          
          //if both src and dest are positive but different
          if (inbinpt >= 0) & (outbinpt >= 0) & (outbinpt <> inbinpt) then 
            ok = %F;
            ratel_log('binary point mismatch\n', [fname, 'error']);
            return;
          elseif inbinpt < 0 & outbinpt >= 0 then 
            ininfo.binpt(iport_idx) = outbinpt;
          else
            ok = %F;
          end
	  
          insign = ininfo.sign(iport_idx); 
          innbits = ininfo.nbits(iport_idx); 
          inbinpt = ininfo.binpt(iport_idx);
	  ratel_log('after:\n', [fname]);
          msg = msprintf('in: sign(%d) (%d,%d)', insign, innbits, inbinpt);   
          ratel_log(msg+'\n', [fname]);

          inblk.opar(1).in = ininfo;
          bllst(connectmat(jj,3)) = inblk;  

        end //if blocktype
      end //link loop
      if ok then return, end //if ok is still set then gone through all links so return 
    end //second loop
  end  //outer loop
  ok = %T;
endfunction //ratel_adjust_fp
