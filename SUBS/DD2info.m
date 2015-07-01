function DDi=DD2info(DD)
   take={'FieldKeys','contour','debugmode','parameters','pattern','switchs','template','thresh','time'}  ;
   for tk=take
      DDi.(tk{1})=DD.(tk{1}); 
   end    
end