%%
a=load('/scratch/uni/ifmto/u300065/FINAL/dataaviI/EDDIES/EDDIE_19940105_-80-+80_000-360')
pass=a.pass;
FN=fieldnames(pass.Cycs)

NN=numel(pass.Cycs);
%%
clear AA
AA.C=false(NN,numel(FN));
AA.AC=false(NN,numel(FN));
%%



for ff=1:numel(FN)
   fn=FN{ff};   
   for ii=1:NN
       if mod(ii,1000)==0
           fprintf('%d%%\n',round(ii*100/NN))
       end
      if isempty(pass.Cycs(ii).(fn)) 
          pass.Cycs(ii).(fn)=false;
      end
      if isempty(pass.AntiCycs(ii).(fn)) 
          pass.AntiCycs(ii).(fn)=false;
      end 
      
      AA.C(ii,ff) =   pass.Cycs(ii).(fn);
      AA.AC(ii,ff) =   pass.AntiCycs(ii).(fn);      
   end    
end

%%


cc = cell2mat(extractfield(cell2mat(extractfield(a.Cycs,'coor')),'exact'))
ca = cell2mat(extractfield(cell2mat(extractfield(a.AntiCycs,'coor')),'exact'))


%%
close all


for ii = 1:numel(cc)
    hold on
   plot(cc(ii).x,cc(ii).y,'black') 
end

for ii = 1:numel(ca)
   plot(ca(ii).x,ca(ii).y,'red') 
end