
function S04b_analyzeEddyThresh
    %% init
    DD=initialise('eddies',mfilename);
    main(DD)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    
%     numDays=DD.checks.passedTotal;
    numDays=1;
   
    sens=DD.FieldKeys.senses';
    
    for jj=1:numDays
        passIn=read_fields(DD,jj,'eddies','pass');
        filename=read_fields(DD,jj,'eddies','filename');
        for ss=1:2
            passToday=passIn.(sens{ss});
            fieldNamesPass=fieldnames(passToday);
            M=false(numel(fieldNamesPass),numel(passToday));
            for ff=1:numel(fieldNamesPass)
                fn=fieldNamesPass{ff}   ;
                paCell=cellfun(@(c) {(~isempty(c) && c)}, {passToday.(fn)});
                M(ff,:)=cell2mat(paCell);
            end
            Ms{ss}=sum(M,2)./numel(passToday)*100;
            MsRel{ss}= Ms{ss}./[100;Ms{ss}(1:end-1)]*100;
            out.passMatrix(ss).all=M;
            out.passMatrix(ss).prcntge=Ms{ss};
            out.passMatrix(ss).prcntRel2Before=MsRel{ss};
        end
        out.passMatrixFields=fieldNamesPass;
        save(filename.self,'-struct','out','-append');
        %%
        save forbarplot
        makebarplot
    end
    
end


function makebarplot
    flushCell=@(c) cat(2,c{:});
    load forbarplot
    %%
    barh(1:numel(fieldNamesPass),   cat(2,out.passMatrix.prcntge))
    set(gca,'yticklabel',fieldNamesPass)
    set(gca,'xtick',sort(unique( cat(1,out.passMatrix.prcntge))))
    set(gca,'xticklabel','')
    legend('anti-cyclones','cyclones')
    xlab={['rel. pass: ' flushCell(cellfun(@(c) sprintf(['- %03.0f%% '],c) ,num2cell(MsRel{1})','uniformoutput',false))];...
        ['tot. pass: ' flushCell(cellfun(@(c) sprintf(['- %03.0f%% '],c) ,num2cell(Ms{1})','uniformoutput',false)) ];...
        ['rel. pass: ' flushCell(cellfun(@(c) sprintf(['- %03.0f%% '],c) ,num2cell(MsRel{2})','uniformoutput',false))];...
        ['tot. pass: ' flushCell(cellfun(@(c) sprintf(['- %03.0f%% '],c) ,num2cell(Ms{2})','uniformoutput',false)) ];...
        }; %#ok<*USENS>
    title(xlab(1:2),'color','blue')
    xlabel(xlab(3:4),'color','red')
    savefig(DD.path.root,100,1200,800,sprintf('pass-%s_day_%04.0f', datestr(now,'mmdd-HHMM'),jj))
end
