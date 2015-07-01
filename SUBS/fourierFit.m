% http://www3.nd.edu/~nancy/Math30650/Matlab/Demos/fourier_series/fourier_s
% eries.html
function [cfitOut] = fourierFit(Xin,Yin,fouriOrder)
	if mod(numel(Yin),2)~=0
		error('fourierFit:moderr','mod(N,2)~=0  not implemented yet');
	end
  %Xequi =linspace(0,diff(Xin([1,end]))); 
	xShift =diff(Xin([1 end]))/2 + Xin(1);
	Xequi = reshape(Xin,1,[]) - xShift;      % assuming equidistance !!!
	Yin = reshape(Yin,1,[]);
	%% make periodic and rep *3
	Y = mirrorLR(Yin,1);
	X = mirrorLR(Xequi,0);
	Lx = diff(X([1 end]));
	%% init
	arg = pi/(Lx/2);
	coeffs(fouriOrder+1) = struct;
	%% 	The kth Fourier coefficients
	for k=0:fouriOrder
		kargx=X*(k*arg);
		coeffs(k+1).cos = trapz(X,Y.*cos(kargx)/(Lx/2));
		coeffs(k+1).sin = trapz(X,Y.*sin(kargx)/(Lx/2));
	end
	%% build fit object	
	T = buildFitObjectTerms(fouriOrder,arg,xShift);
	C = buildFitObjectCoeffs(fouriOrder);
	f = fittype(T,'coefficients',C);
	args = reshape(struct2cell(coeffs),1,[]);
	cfitOut = cfit(f,args{:});
	% 	plot(X,cfitOut(X),X,Y); axis tight;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function C = buildFitObjectCoeffs(N)
	C = cell((N+1),2);
	for k=0:N
		C(k+1,:) = {sprintf('a%d',k),sprintf('b%d',k)};
	end
	C = reshape(C',1,[]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function T = buildFitObjectTerms(N,trigArg,xShift)
	T = cell((N+1),2);
	T(0+1,:) = {'0.5','0'};
	for k=1:N
		argCos = sprintf('cos(%d*%0.6g*(x-%0.6g))',k,trigArg,xShift);
		argSin = sprintf('sin(%d*%0.6g*(x-%0.6g))',k,trigArg,xShift);
		T(k+1,:) ={argCos,argSin};
	end
	T = reshape(T',1,[]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function YX=mirrorLR(yxc,periodic)
	diffa = diff(yxc([1 2]));
	diffb = diff(yxc([end-1 end]));
	diffx = diff(yxc([1 end]));
	if periodic
		yxa = -fliplr(yxc) + 2*yxc(1)   - diffa;
		yxb = -fliplr(yxc) + 2*yxc(end) + diffb;
	else
		yxa = yxc - diffx - diffa;
		yxb = yxc + diffx + diffb;
	end
	YX = [yxa, yxc, yxb];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% clf
% for k=1:fouriOrder+1
% 	hold on
% 	plot(sum(term(1:k,:),1),'color',rainbow(1,1,1,k,fouriOrder+1))
% end
% plot(Y,'linewidth',2)
% axis([100 200 -.25 0])

%
%
% 	f = fittype('a*x^2+b*exp(n*x)')
% 	f =
% 	General model:
% 	f(a,b,n,x) = a*x^2+b*exp(n*x)
% 	c = cfit(f,1,10.3,-1e2)
% 	c =
% 	General model:
% 	c(x) = a*x^2+b*exp(n*x)
% 	Coefficients:
% 	a =           1
% 	b =        10.3
% 	n =        -100
%
