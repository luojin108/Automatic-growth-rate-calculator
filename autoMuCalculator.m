classdef autoMuCalculator
    %The class is just a wrapper including 2 functions.
    methods (Static)
        
        function result=muCalculate(XData,YDataBlanked,ThresValue,MinR2adj)
            %%This method is developed based on the idea from
            % https://doi.org/10.1186/s13104-017-2945-6. 
            %
            % Calculates a specific growth rate as slope from log-transformed vector of
            % biomass signals. Data vectors are iteratively cropped until several
            % stopping criteria are met in order to extract the data subset orginating
            % from the exponential growth phase.
            % 
            % INPUT
            %   XData: Vector of data points for independent variable
            %   YDataBlanked: Vector of data points for dependent variable
            %   ThresValue: User defined threshold as limit of detection for biomass 
            %   quantification
            %   MinR2adj: Minimal adjusted R2 from linear regression as one of the 
            %   stopping criteria
            % 
            % OUTPUT
            %   result: Structure variable returning results including Mu, R^2,
            %   StartTime and EndTime
            StartColumn = find( YDataBlanked > ThresValue,1);
            LastColumnInTheFirstIteration = length(YDataBlanked);
            Mu1=[];
            for i = LastColumnInTheFirstIteration:-1:StartColumn

                if i-2 < 1
                     %If a satisfied result is still not obtained, break
                     break
                end
                X = XData(1,StartColumn:i);
                Y = YDataBlanked(1,StartColumn:i);
                InY = log(Y);
                DeltaEnd = YDataBlanked(1,i) - YDataBlanked(1,i-1);
                DeltaPre = YDataBlanked(1,i-1) - YDataBlanked(1,i-2);
                LROutput = fitlm(X,InY);
                RSquared = LROutput.Rsquared.Adjusted;
                CI = coefCI(LROutput,0.05);
                Mu = LROutput.Coefficients.Estimate(2);
                if (RSquared >= MinR2adj) && (DeltaEnd > DeltaPre)...
                        && (DeltaEnd > 0) && (DeltaPre > 0)...
                        && (Mu > CI(2,1)) && (Mu < CI(2,2))
                    Mu1 = Mu;
                    RSquared1 = RSquared;
                    LastColumnPassedForFurtherCalculation = i;
                    TimeInLastColumn = XData(1,i);
                    TimeInStartColumnBeforeAdjustment = XData(1,StartColumn);
                    StartColumnBeforeAdjustment = StartColumn;
                    EndColumn = i;

                    break; 
                end  
            end
            Mu2=[];
            if ~isempty(Mu1) && (StartColumn>1)
                for k = 1:1:StartColumn - 1
                    X = XData(1,k:LastColumnPassedForFurtherCalculation);
                    Y = YDataBlanked(1,k:LastColumnPassedForFurtherCalculation);
                    InY = log(Y);
                    a = [];
                    %a is a vector, containing all the biomass increase from k column
                    %to StartColumn
                    for j = 1:1:StartColumn-k
                        a(j) = YDataBlanked(1,k+j) - YDataBlanked(1,k+j-1);
                    end
                    if k == 1
                        DeltaNext = YDataBlanked(1,k+1) - YDataBlanked(1,k);
                        LROutput = fitlm(X,InY);
                        RSquared = LROutput.Rsquared.Adjusted;
                        CI = coefCI(LROutput,0.05);
                        Mu = LROutput.Coefficients.Estimate(2);
                        if (RSquared >= MinR2adj)...
                            &&(DeltaNext > 0) &&(all(a > 0))...
                            && (Mu > CI(2,1)) && (Mu < CI(2,2))... 

                            Mu2 = Mu;
                            RSquared2 = RSquared;
                            TimeInStartColumnAfterAdjustment = XData(1,k);
                            StartColumnAfterAdjustment = k;


                            break;
                        end  
                    end
                    if k>1
                        DeltaNext = YDataBlanked(1,k+1) - YDataBlanked(1,k);
                        DeltaStart =YDataBlanked(1,k) - YDataBlanked(1,k-1);
                        LROutput = fitlm(X,InY);
                        RSquared = LROutput.Rsquared.Adjusted;
                        CI = coefCI(LROutput,0.05);
                        Mu = LROutput.Coefficients.Estimate(2);
                        if (RSquared >= MinR2adj) && (DeltaNext > DeltaStart)...
                            &&(DeltaNext > 0) &&(all(a > 0))...
                            && (Mu> CI(2,1)) && (Mu < CI(2,2))...

                            Mu2 = Mu;
                            RSquared2 = RSquared;
                            TimeInStartColumnAfterAdjustment = XData(1,k);
                            StartColumnAfterAdjustment = k;

                            break;
                        end  
                    end
                end

                result.EndTime = TimeInLastColumn;
                result.EndColumn = EndColumn;
                if isempty(Mu2)
                    result.Mu = Mu1;
                    result.RSquared = RSquared1;
                    result.StartTime = TimeInStartColumnBeforeAdjustment;
                    result.StartColumn = StartColumnBeforeAdjustment;
                else
                    result.Mu = Mu2;
                    result.RSquared = RSquared2;
                    result.StartTime = TimeInStartColumnAfterAdjustment;
                    result.StartColumn = StartColumnAfterAdjustment;

                end

            else
                fprintf("Errors!");
                result.Mu = 0;
                result.RSquared = 0;
                result.StartTime = 0;
                result.EndTime = 0;
                result.StartColumn = 0;
                result.EndColumn = 0;
            end
            
        end
        function resultTable = calculateMuInBatch(filePath, sheetName, xDataRange, yDataRange, ThresValue, MinR2adj, producFigures)
            % This function calculates specific growth rate in batch. There is the
            % option to generate plots of growth and logarithmic growth for
            % result-inspecting purpose.
            %   
            % INPUT
            %   filePath: Full path of the file (Exel file)
            %
            %   sheetName: Sheet name of your data in the Exel, e.g., "Sheet1"
            %
            %   xDataRange: The range of the cells in the Exel, containing the x axis
            %   data, e.g., "B1:AX1".
            %
            %   yDataRange: The range of the cells in the Exel, containing the y axis
            %   data, e.g., "B2:AX167".
            %
            %   ThresValue: User defined threshold as limit of detection for biomass 
            %   quantification.
            %
            %   MinR2adj: Minimal adjusted R^2 from linear regression as one of the 
            %   stopping criteria
            %
            %   producFigures: This is an optional parameter, if this is set to true, 
            %   the function will produce figures under the current directory. This will make the
            %   whole process slow. But the option is very useful if you want to
            %   inspect and visualize the data.
            % 
            % OUTPUT
            %   resultTable: Table containing the specific growth rate Mu, RSquared  
            %   start time of the linear part, and end time of the linear part.

            if nargin < 7
                producFigures = false;
            end
            XData=xlsread(filePath,sheetName,xDataRange);
            YData=xlsread(filePath,sheetName,yDataRange);


            dataSize = size(YData);
            resultMatrix = zeros(dataSize(1),4);
            for i = 1:1:dataSize(1)
                 output = muCalculate(XData,YData(i,:),ThresValue,MinR2adj);
                 resultMatrix(i,1) = output.Mu;
                 resultMatrix(i,2) = output.RSquared;
                 resultMatrix(i,3) = output.StartTime;
                 resultMatrix(i,4) = output.EndTime;
                 if producFigures
                     clf;
                     InData = log(YData(i,:));
                     StartColumn = output.StartColumn;
                     EndColumn = output.EndColumn;
                     yyaxis left;
                     plot(XData,YData(i,:),'-o','MarkerSize',2);
                     ylabel('Biomass');
                     hold on
                     yyaxis right;
                     plot(XData,InData,'-o','MarkerSize',2);
                     ylabel('In(Biomass)');

                     if (StartColumn ~= 0) && (EndColumn ~= 0)
                        hold on
                        yyaxis right;
                        plot(XData(StartColumn:EndColumn),InData(StartColumn:EndColumn),'o','MarkerSize',3,'MarkerFaceColor','black');
                     end
                     fileName=sprintf('%s.jpg',num2str(i));
                     saveas(gcf,fileName);
                     clf;
                 end


            end
            resultTable = array2table(resultMatrix, 'VariableNames',{'Mu','RSquared','StartTime','EndTime'});


            
        end    
    end
end

