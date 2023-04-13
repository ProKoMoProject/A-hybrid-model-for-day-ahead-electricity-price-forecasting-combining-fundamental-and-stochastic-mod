# A hybrid model for day ahead electricity price forecasting: Combining fundamental and stochastic modelling

### Mira Watermeyer, Thomas Möbius, Oliver Grothe, Felix Müsgens

The accurate prediction of short-term electricity prices is vital for effective trading strategies, power plant scheduling, profit maximisation and efficient system operation. However, uncertainties in supply and demand make such predictions challenging. We propose a hybrid model that combines a techno-economic energy system model with stochastic models to address this challenge. The techno-economic model in our hybrid approach provides a deep understanding of the market. It captures the underlying factors and their impacts on electricity prices, which is impossible with statistical models alone. The statistical models incorporate non-techno-economic aspects, such as the expectations and speculative behaviour of market participants, through the interpretation of prices. The hybrid model generates both conventional point predictions and probabilistic forecasts, providing a comprehensive understanding of the market landscape. Probabilistic forecasts are particularly valuable because they account for market uncertainty, facilitating informed decision-making and risk management. Our model delivers state-of-the-art results, helping market participants to make informed decisions and operate their systems more efficiently.

### Keywords:
Electricity price forecasting
Hybrid model
Energy system modelling, 
Stochastic modelling,
Probabilistic forecasting 

### Links: 
tba

### The code reproduces the benchmarks from the paper 
All scripts can be found in the folder "02/scripts". 
In the following, we list the main files to reproduce the results. Other files in the folder are included automatically in the stepwise calculations and do not have to run on their own. 

Step 1: Data Pre-Processing

For the improvement of the transmission system operators day-ahead load forecast we refer to https://github.com/ProKoMoProject/Enhancing-Energy-System-Models-Using-Better-Load-Forecasts

Step 1/2: Data Pre-Processing and Parameter Density

Model and forecast of the two-day-ahead load forecast (point forecast and scenario forecast) are provided in file "2_2DALoadforecast_point_scenarios.py". 

Step 3: Energy System Optimisation Step

i) save all .gms files and the "Project_ProKoMo" file in the same folder

ii) create a subfolder "data" and save there all .xlsx files. Note that gas prices are not provided (due to copyright issues) and have to be added in the data file "InputData_allyears.xlsx"

iii) create a subfolder "results" to save the model output

iv) open a .gms file for the respective year (e.g. "ProKoMo_rollingwindow_2016.gms") and run the model. All settings are already prepared in the code.

Step 4: Post-Processing

To forecast the individual point predictions of the six sub-models (univariate and multivariate), run file "4a_Post-processing step - Point prediction.m". 

The probabilistic forecast is calculated through file "4b_Post-processing step - Probabilistic prediction.py". 

### Results from the paper 
All results generated with the hybrid model are uploaded in the folder "03/results". 

File "hybrid model - point and probabilistic forecasts of the day-ahead electricity price.xlsx" shows the day-ahead price prediction, point and probabilistic, which is generated with the hybrid model.  

File "hybrid model - results of the steps.xlsx" lists the results of the four steps.  

### Data input to run code
To run the code, some input data are required. In this repository, we provide all input data generated individually. For the input data that were used unchanged from the sources mentioned in the paper, we refer to the corresponding sources for the generation of the input data. 

### Citing IntEG

The model published in this repository is free: you can access, modify and share it under the terms of the <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>. This model is shared in the hope that it will be useful for further research on topics of risk-aversion, investments, flexibility and uncertainty in ectricity markets but without any warranty of merchantability or fitness for a particular purpose. 

If you use the model or its components for your research, we would appreciate it if you
would cite us as follows:
```
This paper is in review. The reference to the working paper version is as follows:

tba
```
