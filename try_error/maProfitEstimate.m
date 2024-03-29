function [returnRate, total]=maProfitEstimate(num, window, showPlot)
% maProfitEstimate: Estimate the profit of the trading strategy of moving average
%
%	Usage:
%		returnRate=maProfitEstimate(adjClose, window, showPlot)
%
%	Description:
%		returnRate=maProfitEstimate(adjClose, window, showPlot) returns the return rate of a trading strategy
%
%	Example:
%		file='spy.csv';
%		fprintf('Reading %s...\n', file);
%		num=csvread(file, 1, 1);
%		adjClose=num(:,5);
%		window=120;
%		returnRate=maProfitEstimate(adjClose, window, 1);
%		fprintf('Return rate=%g%%\n', returnRate*100);

%	Roger Jang, 20171125

if nargin<1, selfdemo; return; end
if nargin<2, window=120; end
if nargin<3, showPlot=0; end

%% Parameters and data
capital=1;	% Initial cash
capitalOrig=capital;
%% Start rolling
adjClose=num(:,5);
dataCount=length(adjClose);
suggestedAction=zeros(dataCount,1);	% suggested actions based on MA, 1 for buy, -1 for sell
ma=zeros(dataCount,1);	% moving average
stockHolding=zeros(dataCount,1);	% unit of stock in hand
total=zeros(dataCount,1);	% total assets
realAction=zeros(dataCount,1);	% real actions
total(1)=capital;
for i=1:dataCount
	%currPrice=adjClose(i);	% Today's price
    %今日開盤價
    currPrice=num(i,5) - num(i,4) + num(i,1);
	%[suggestedAction(i), ma(i)]=maStrategy(adjClose(1:i-1), currPrice, window);	% Suggested action
	[suggestedAction(i), ma(i)]=maStrategyLin(adjClose(1:i-1), window);	% Suggested action
    if i>1, stockHolding(i)=stockHolding(i-1); end		% Initial holding from yesterday
	switch suggestedAction(i)
		case 1	% "buy"
			if stockHolding(i)==0
				stockHolding(i)=capital/currPrice;
				capital=0;
				realAction(i)=1;
			end
		case -1	% "sell"
			if stockHolding(i)>0
				capital=stockHolding(i)*currPrice;
				stockHolding(i)=0;
				realAction(i)=-1;
			end
		case 0	% Do nothing
		otherwise
			disp('Unknown action!');
	end
	total(i)=capital+stockHolding(i)*currPrice;
%	fprintf('%d/%d: suggestedAction=%d, stockHolding=%g, capital=%g, realAction=%d, total=%g\n', i, dataCount, suggestedAction(i), stockHolding(i), capital, realAction(i), total(i));
end
returnRate=(total(end)-capitalOrig)/capitalOrig;
%% Plotting
if showPlot
	subplot(411); plot([adjClose, ma]); title(sprintf('Price & %dMA', window)); set(gca, 'xlim', [1, dataCount]);
	set(gca, 'xlim', [1, dataCount]);
	axisLimit=axis;
%	line(axisLimit(1:2), U*[1 1], 'color', 'r');
%	hU=text(axisLimit(2), U, sprintf('U=%g', U));
%	hD=text(axisLimit(2), D, sprintf('D=%g', D));
%	line(axisLimit(1:2), D*[1 1], 'color', 'g');
	color={'g', 'b', 'r'};
	subplot(412); plot(realAction); title(sprintf('Action (��buy=%d, #sell=%d)', sum(realAction==1), sum(realAction==-1))); set(gca, 'xlim', [1, dataCount]);
	for i=1:length(suggestedAction)
		if realAction(i)==0; continue; end
		line(i, realAction(i), 'marker', '.', 'color', color{realAction(i)+2});
	end
	subplot(413); plot(stockHolding); title('Stock holdings'); set(gca, 'xlim', [1, dataCount]);
	subplot(414); plot(100*(total-capitalOrig)/capitalOrig); title(sprintf('Return rate, final=%g%%', returnRate(end)*100)); set(gca, 'xlim', [1, dataCount]);
	line(axisLimit(1:2), [0 0], 'color', 'r');
	xlabel('Data index'); ylabel('Return rate (%)');
end

% ====== Self demo
function selfdemo
mObj=mFileParse(which(mfilename));
strEval(mObj.example);