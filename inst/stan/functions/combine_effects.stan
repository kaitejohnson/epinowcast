/**
 * Combine nested regression effects using design matrices
 * 
 * This function combines nested regression effects based on a design matrix and
 * applies effect pooling using a second design matrix. It allows for scaling 
 * of effects with specified standard deviations, enabling the pooling of these 
 * effects. The function can also incorporate an intercept into the linear 
 * predictions.
 * 
 * @param intercept Array containing the regression intercept (length one).
 *
 * @param beta Vector of regression effects, typically unit-scaled for possible 
 * rescaling with beta_sd.
 *
 * @param design Design matrix mapping observations (rows) to effects (columns).
 *
 * @param beta_sd Vector of standard deviations for scaling and pooling effects.
 *
 * @param sd_design Design matrix relating effect sizes to standard deviations.
 * The first column indicates no scaling for independent effects.
 *
 * @param add_intercept Binary flag to indicate if the intercept should be
 * added to the beta vector.
 * 
 * @return A vector of linear predictions without error.
 * 
 * @note The function scales the beta vector using the product of beta_sd and 
 * sd_design, then combines these scaled effects with the design matrix. 
 * If `add_intercept` is true, the intercept is included in the linear 
 * predictions. The function handles cases with no effects by returning 
 * a vector of the intercept repeated for each observation.
 * 
 * @code
 * # Example usage in R:
 * intercept <- 1
 * beta <- c(0.1, 0.2, 0.4)
 * design <- t(matrix(c(1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1), 4, 4))
 * beta_sd <- c(0.1)
 * sd_design <- t(matrix(c(1, 0, 0, 1, 0, 1), 2, 3))
 * 
 * # Check effects are combined as expected:
 * combine_effects(intercept, beta, design, beta_sd, sd_design, TRUE)
 * # Output: 1.04 1.12 1.00 1.04
 * @endcode
 */
vector combine_effects(array[] real intercept, vector beta, matrix design,
                       vector beta_sd, matrix sd_design, int add_intercept) {
  int nobs = rows(design);
  int neffs = num_elements(beta);
  int sds = num_elements(beta_sd);
  vector[neffs + add_intercept] scaled_beta;
  vector[sds + 1] ext_beta_sd;
  ext_beta_sd[1] =  1.0;
  if (neffs) {
    ext_beta_sd[2:(sds+1)] = beta_sd;
      if (add_intercept) {
        scaled_beta[1] = intercept[1];
      }
    scaled_beta[(1+add_intercept):(neffs+add_intercept)] =
      beta .* (sd_design * ext_beta_sd);
    return(design * scaled_beta);
  }else{
    return(rep_vector(intercept[1], nobs));
  }
}
