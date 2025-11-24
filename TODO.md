# TODO - Time Series Seasonality Analysis

## Pending Features

### Pre-Transformation
- [ ] **AIC Test for automatic transformation selection**
  - Implement automatic selection between None/Log transformation using AIC criterion
  - Fit model with original data
  - Fit model with log-transformed data
  - Compare AIC values and select best option
  - Display result to user with justification

### Outlier Control
- [ ] Implement outlier detection (tsoutliers, IQR, boxplot methods)
- [ ] Show outlier locations in the series
- [ ] Option to interpolate/replace outliers
- [ ] Compare original vs cleaned series

### Statistical Tests
- [ ] Validate assumptions before applying tests (Shapiro-Wilk, Bartlett)
- [ ] Visual alerts when assumptions fail
- [ ] Indicate which tests are valid based on assumptions

### Future Enhancements
- [ ] Add more visualization options to the dropdown menu
- [ ] Export results to PDF report
- [ ] Autoregressive analysis module
- [ ] Distribution comparison with Kuiper test
