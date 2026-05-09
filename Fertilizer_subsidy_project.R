#loading the required libraries
library(readxl) # for loading the dataset
library(tidyr) # for data cleaning
library(stringr) # for string manipulation
library(dplyr) # for data manipulation
library(ggplot2) # for data visualization
library(tseries) # for ADF stationarity test
library(forecast) # for time series modelling and forecasting
library(lmtest) # for diagnostic checking for linear regression models
library(sandwich) # for computing standard errors

# loading the required data set
agricultural_production <- read_excel("C:\\Users\\stalo\\Documents\\School Work\\Fourth Year Project\\Kenyas_Agricultural_Production.xlsx")
agricultural_production

View(agricultural_production)

# looking for missing values in our data set
colSums(is.na(agricultural_production))


agri_production_cleaned <- agricultural_production %>%
  
  # select the only columns strictly needed for analysis
  select(Year, Item, Element, Unit, Value) %>%
  
  # filter the two elements you need
  filter(Element %in% c("Production", "Area harvested")) %>%
  
  # Turn Element column to new Column headers
  pivot_wider(
    names_from = Element,
    values_from = Value,
    values_fill = 0
  ) %>%
  
  # renaming Production to production_tonnes and Area harvested to 
  #area_harvested
  
  rename(
    production_tonnes = Production,
    area_hectares = `Area harvested`
  )

View(agri_production_cleaned)

# Aggregation
# Create Aggregate National Output
national_time_series <- agri_production_cleaned %>%
  group_by(Year) %>%
  summarise(
    #sum all individual crop production for the year
    Aggregate_National_Output = sum(production_tonnes, na.rm = TRUE),
    
    total_area_hectares = sum(area_hectares)
    
    
    
  ) %>%
  
  # constructing the model variables
  # convert to natural logarithms to standardize the variance and facilitate 
  # the interpretation of results as percentage growth rates
  mutate(
    ln_output = log(Aggregate_National_Output),
    land_area = log(total_area_hectares),
    intervention = ifelse(Year >= 2009, 1, 0),
    post_time = ifelse(Year >= 2009, Year-2008, 0)
  )

View(national_time_series)

summary(national_time_series)

agri_production_cleaned %>%
  summarise(across(c(production_tonnes, area_hectares), ~ sd(.x, na.rm = TRUE)))

# plotting the time series line graph of log-transformed aggregate production 
# over time
ggplot(national_time_series, aes(x = Year, y = ln_output)) +
  
  geom_line(color = "steelblue", linewidth = 1) + 
  
  scale_x_continuous(breaks = seq(1961, 2021, by = 10)) +
  
  labs(
    title = "Aggregate Production Over Time",
    x = "Year",
    y = "Aggregate Production"
  ) +
  
  theme_minimal() 

# plotting the time series line graph for aggregate production over time
ggplot(national_time_series, aes(x = Year, y = Aggregate_National_Output)) +
  
  geom_line(color = "steelblue", linewidth = 1) + 
  
  scale_x_continuous(breaks = seq(1961, 2021, by = 10)) +
  
  labs(
    title = "Aggregate Production Over Time",
    x = "Year",
    y = "Aggregate Production"
  ) +
  
  theme_minimal() 

#checking for stationarity using the Augmented Dicky Fuller Test
adf_result<-adf.test(national_time_series$ln_output)
print(adf_result)

# first differencing to make the data stationary
diff_national_time_series<-diff(national_time_series$ln_output)

# checking for stationarity on the differenced data using the Augmented Dicky 
# Fuller Test
diff_adf_result<-adf.test(diff_national_time_series)
print(diff_adf_result)
View (national_time_series)

# run the baseline Interrupted Time Series Model
model_its <- lm(ln_output ~ Year + intervention + post_time + land_area,
                data = national_time_series)
summary(model_its)

# Check Residuals for Autocorrelation
# Durbin-Watson test
dwtest(model_its)

# Visual check
par(mfrow = c(1, 2))
plot(residuals(model_its), type = "l",
     main = "Residuals over Time", ylab = "Residuals")
abline(h = 0, col = "red")
acf(residuals(model_its), main = "ACF of Residuals")


# Convert ln_output to ts object
ln_output_ts <- ts(national_time_series$ln_output, start = 1961, frequency = 1)

# Building the regressor matrix
xreg_matrix <- cbind(
  time         = national_time_series$Year,
  intervention = national_time_series$intervention,
  post_time    = national_time_series$post_time,
  land_area      = national_time_series$land_area        
)

# Fit the model
model_arimax <- auto.arima(ln_output_ts,
                           xreg          = xreg_matrix,
                           seasonal      = FALSE,
                           stepwise      = FALSE,
                           approximation = FALSE)
# Model Evaluation

# overall model summary
summary(model_arimax)

# Training Set Error Measures (MAPE, RMSE, MAE)
accuracy(model_arimax)

# Information Criteria (AIC, AICc, BIC)
cat("AIC:", AIC(model_arimax), "\n")
cat("BIC:", BIC(model_arimax), "\n")

model_arimax$aicc
model_arimax$aic
model_arimax$bic

# Residual ACF1 — Confirming Autocorrelation is Resolved
# Formal check - ACF of final model residuals
par(mfrow = c(1, 2))

# Residuals over time
plot(residuals(model_arimax), type = "l",
     main = "ARIMAX Residuals over Time",
     ylab = "Residuals",
     xlab = "Year")
abline(h = 0, col = "red")

# ACF plot
acf(residuals(model_arimax),
    main = "ACF of ARIMAX Residuals")

# Reset plot layout
par(mfrow = c(1, 1))

# plotting the actual versus fitted values
national_time_series$fitted <- fitted(model_arimax)

ggplot(national_time_series, aes(x = Year)) +
  geom_line(aes(y = ln_output, color = "Actual"), linewidth = 1) +
  geom_line(aes(y = fitted, color = "Fitted"), linewidth = 1,
            linetype = "dashed") +
  geom_vline(xintercept = 2009, linetype = "dotted",
             color = "darkgreen", linewidth = 1) +
  annotate("text", x = 2010, y = min(national_time_series$ln_output),
           label = "post policy",
           color = "darkgreen", hjust = 0) +
  scale_color_manual(values = c("Actual" = "steelblue",
                                "Fitted" = "red")) +
  labs(
    title    = "Effect of 2009 Subsidy Policy on Agricultural Output",
    x        = "Year",
    y        = "Total Production",
    color    = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

