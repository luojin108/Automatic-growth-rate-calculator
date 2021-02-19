# Automatic-growth-rate-calculator
The calculator can determine the linear part of a growth curve automatically and calculate the specific growth rate for multiple growth curves in batch mode.

The class autoMuCalculator is a wrapper containing 2 functions. 

The first function is muCalculate(), which is is developed based on the idea from \[1\]. The function calculates a specific growth rate as slope from log-transformed vector of biomass signals. Data vectors are iteratively cropped until severa stopping criteria are met in order to extract the data subset orginating from the exponential growth phase.

The second function is calculateMuInBatch(), which calculates the specific growth rates in batch mode. There is an option to generate plots of growth and logarithmic growth for result-inspecting purpose.


\[1\] Hemmerich, J., Wiechert, W. & Oldiges, M. Automated growth rate determination in high-throughput microbioreactor systems. BMC Res Notes 10, 617 (2017). https://doi.org/10.1186/s13104-017-2945-6
